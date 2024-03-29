<template>
  <div v-if="isLoading" class="px-4">Loading...</div>
  <section v-if="messages" class="flex flex-col-reverse" role="log">
    <MessageItem
      v-for="(message, index) in messages"
      :key="message.id"
      :message="message"
      :show-header="checkMessageCompact(message, messages[index + 1])"
    />
  </section>
</template>

<script lang="ts">
import { computed, defineComponent, ref, watch, nextTick } from 'vue'
import { useRoute } from 'vue-router'
import { useInfiniteQuery } from 'vue-query'
import { getMessages } from '@/api/handler/messages'
import MessageItem from './MessageItem.vue'
import { Message } from '@/types'
import useMessageSocket from '@/api/ws/useMessageSocket'
import { getTimeDifference } from '@/helpers'

export default defineComponent({
  name: 'MessageList',
  components: { MessageItem },
  emits: ['scrollBottom'],
  setup(_props, { emit }) {
    const route = useRoute()
    const channelId = route.params.channelId as string
    const qKey = `messages-${channelId}`
    const hasMore = ref(false)
    useMessageSocket(channelId, qKey)

    const { data, isLoading, fetchNextPage } = useInfiniteQuery(
      qKey,
      async ({ pageParam = null }) => {
        const { data } = await getMessages(channelId, pageParam)
        if (data.length !== 35) hasMore.value = false
        // if (data) return data.pages.flatMap((p: any) => p)
        return data
      },
      {
        getNextPageParam: (lastPage) =>
          hasMore.value && lastPage.length
            ? lastPage[lastPage.length - 1].createdAt
            : '',
      }
    )

    const messages = computed(() => {
      return data.value?.pages.flatMap((p: any) => p)
    })
    watch(messages, (newVal, oldVal) => {
      if (newVal?.[0] !== oldVal?.[0]) {
        nextTick(() => {
          emit('scrollBottom')
        })
      }
    })

    function checkMessageCompact(m1: Message, m2: Message) {
      if (!m2) return false // last message
      if (m1.user.id !== m2.user.id) return false
      return getTimeDifference(m1.createdAt, m2.createdAt) <= 5
    }

    return { isLoading, messages, checkMessageCompact }
  },
})
</script>
