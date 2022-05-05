FROM expensely/lambda-jmeter:latest as load-tests

ENV JMETER_TEST_FILE='/tmp/load.jmx'
ENV JMETER_VARIABLE_users_file_path='/tmp/users.csv'
ENV EXPORT_JMETER_HTML=TRUE

WORKDIR /tmp
COPY users.csv .
COPY load.jmx .
