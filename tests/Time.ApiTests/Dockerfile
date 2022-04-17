FROM expensely/lambda-postman:latest as api-tests

ARG BUILD_NUMBER=1.0.0-0

WORKDIR /postman
COPY collections collections
COPY environments environments
