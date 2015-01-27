FROM phusion/baseimage:0.9.16
MAINTAINER Jani Leppanen <jani9000@gmail.com>

USER root

RUN apt-get update
RUN apt-get install -y openjdk-7-jdk
RUN apt-get install -y openssh-server

RUN rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN curl -O "http://apache.mirrors.tds.net/spark/spark-1.2.0/spark-1.2.0-bin-hadoop2.4.tgz"
RUN tar -xzf /tmp/spark-1.2.0-bin-hadoop2.4.tgz -C /usr/local/
RUN mv /usr/local/spark-1.2.0-bin-hadoop2.4 /usr/local/spark
RUN rm spark-1.2.0-bin-hadoop2.4.tgz
