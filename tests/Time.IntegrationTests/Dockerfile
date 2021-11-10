FROM node:14 as base
ARG BUILD_NUMBER=1.0.0-0
WORKDIR /app
RUN ls -al
COPY . ./
RUN npm ci
RUN npm run build
RUN npm run package

FROM amazon/aws-lambda-nodejs:14 as lambda
COPY --from=base /app/webpack /var/task
CMD [ "index.handler" ]
