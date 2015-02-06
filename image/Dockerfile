FROM phusion/baseimage:0.9.16
MAINTAINER Jani Leppanen <jani9000@gmail.com>

USER root

RUN apt-get update
RUN apt-get install -y openjdk-7-jdk
RUN apt-get install -y openssh-server

RUN rm -rf /var/lib/apt/lists/*

# Hadoop

WORKDIR /tmp
RUN curl -O "http://mirror.tcpdiag.net/apache/hadoop/common/hadoop-2.6.0/hadoop-2.6.0.tar.gz"
RUN tar -xzf hadoop-2.6.0.tar.gz -C /usr/local/
RUN mv /usr/local/hadoop-2.6.0 /usr/local/hadoop
RUN rm hadoop-2.6.0.tar.gz

ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin:/usr/local/hadoop/bin:/usr/local/hadoop/sbin

WORKDIR /usr/local/hadoop

COPY hadoop_conf/core-site.xml $HADOOP_CONF_DIR/
COPY hadoop_conf/mapred-site.xml $HADOOP_CONF_DIR/
COPY hadoop_conf/hdfs-site.xml $HADOOP_CONF_DIR/
COPY hadoop_conf/yarn-site.xml $HADOOP_CONF_DIR/
COPY hadoop_conf/hadoop-env.sh $HADOOP_CONF_DIR/
COPY hadoop_conf/hadoop-init.sh $HADOOP_CONF_DIR/

RUN echo "export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64" >> $HADOOP_CONF_DIR/yarn-env.sh

# Spark

WORKDIR /tmp
RUN curl -O "http://apache.mirrors.tds.net/spark/spark-1.2.0/spark-1.2.0-bin-hadoop2.4.tgz"
RUN tar -xzf /tmp/spark-1.2.0-bin-hadoop2.4.tgz -C /usr/local/
RUN mv /usr/local/spark-1.2.0-bin-hadoop2.4 /usr/local/spark
RUN rm spark-1.2.0-bin-hadoop2.4.tgz

WORKDIR /usr/local/spark
