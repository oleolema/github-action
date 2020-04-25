FROM maven
MAINTAINER yqh<yqh@qq.com>

ENV CODE /code
ENV WORK /code/work
RUN mkdir -p $CODE \
    && mkdir -p $WORK

WORKDIR $WORK

COPY ./target/*.jar app.jar

EXPOSE 8060
CMD java -jar app.jar
