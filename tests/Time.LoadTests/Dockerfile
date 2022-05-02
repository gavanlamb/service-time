FROM expensely/lambda-jmeter:latest as load-tests

ENV JMETER_TEST_FILE='/jmeter/load.jmx'
ENV JMETER_VARIABLE_users_file_path='/jmeter/users.csv'
ENV EXPORT_JMETER_HTML=TRUE

WORKDIR /jmeter
COPY users.csv .
COPY load.jmx .
RUN mkdir /jmeter/temp
