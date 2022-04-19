FROM expensely/lambda-jmeter:latest as load-tests

ARG BUILD_NUMBER=1.0.0-0

WORKDIR /jmeter
COPY users.csv .
COPY load.jmx .
