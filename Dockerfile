FROM node:lts-alpine3.18 as build-stage


# make the 'app' folder the current working directory
WORKDIR /app

# copy both 'package.json' and 'package-lock.json' (if available)
COPY package*.json ./

# install project dependencies
RUN yarn install

# copy project files and folders to the current working directory (i.e. 'app' folder)
COPY . .

# build app for production with minification
RUN yarn build

# use the lineweight Nginx image from the previus state to the nginx container
FROM nginx:stable-alpine as production-stage

# copy the build application from the previus state to the nginx container
COPY --from=build-stage /app/dist /usr/share/nginx/html

# copy the nginx configuration file 
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

# expose port 80
EXPOSE 80
# start the server
CMD ["nginx", "-g", "daemon off;"]