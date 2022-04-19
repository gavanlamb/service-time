FROM expensely/lambda-jmeter:latest as load-tests

ARG JMETER_TEST_FILE='/jmeter/load.jmx'
ARG EXPORT_JMETER_HTML=TRUE
ARG JMETER_VARIABLE_users_file_path='/jmeter/users.csv'

WORKDIR /jmeter
COPY users.csv .
COPY load.jmx .
