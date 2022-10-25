# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# We need to build from debian:bullseye-slim because openjdk switches its underlying OS
# from debian to oraclelinux from openjdk:12
FROM debian:bullseye-slim

ARG SPARK_VERSION
ARG SPARK_FILE_NAME=spark-${SPARK_VERSION}-bin-without-hadoop
ARG HADOOP_VERSION
ARG HADOOP_FILE_NAME=hadoop-${HADOOP_VERSION}
ARG spark_uid=185

ADD ${SPARK_FILE_NAME}.tgz /tmp/
ADD ${HADOOP_FILE_NAME}.tar.gz /tmp/
ENV SPARK_HOME="/opt/spark"
ENV HADOOP_HOME="/opt/hadoop"

RUN mkdir -p $HADOOP_HOME && \
    mkdir -p $SPARK_HOME && \
    mkdir -p $SPARK_HOME/work-dir && \
    touch $SPARK_HOME/RELEASE

# Only keep the necessary directories and delete the rest
RUN mv /tmp/$SPARK_FILE_NAME/jars $SPARK_HOME/jars && \
    mv /tmp/$SPARK_FILE_NAME/bin $SPARK_HOME/bin && \
    mv /tmp/$SPARK_FILE_NAME/sbin $SPARK_HOME/sbin && \
    mv /tmp/$SPARK_FILE_NAME/kubernetes/dockerfiles/spark/entrypoint.sh /opt/ && \
    mv /tmp/$SPARK_FILE_NAME/kubernetes/dockerfiles/spark/decom.sh /opt/ && \
    rm -r /tmp/$SPARK_FILE_NAME

RUN mv /tmp/$HADOOP_FILE_NAME/bin $HADOOP_HOME/ && \
    mv /tmp/$HADOOP_FILE_NAME/etc $HADOOP_HOME/ && \
    mv /tmp/$HADOOP_FILE_NAME/include $HADOOP_HOME/ && \
    mv /tmp/$HADOOP_FILE_NAME/lib $HADOOP_HOME/ && \
    mv /tmp/$HADOOP_FILE_NAME/libexec $HADOOP_HOME/ && \
    mv /tmp/$HADOOP_FILE_NAME/sbin $HADOOP_HOME/ && \
    mkdir $HADOOP_HOME/share/ && \
    mv /tmp/$HADOOP_FILE_NAME/share/hadoop $HADOOP_HOME/share/ && \
    rm -r /tmp/$HADOOP_FILE_NAME