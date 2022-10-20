#ARG SPARK_VERSION
#FROM ourapache/spark:$SPARK_VERSION
#
#COPY ${SPARK_HADOOP_ROOT}/target/spark-image-jars/* /opt/spark/jars/
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a COPY ${SPARK_HADOOP_ROOT}/of the License at
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

ARG spark_uid=185
ARG SPARK_HADOOP_ROOT=tmp_docker_image

# Before building the docker image, first build and make a Spark distribution following
# the instructions in https://spark.apache.org/docs/latest/building-spark.html.
# If this docker file is being used in the context of building your images from a Spark
# distribution, the docker build command should be invoked from the top level directory
# of the Spark distribution. E.g.:
# docker build -t spark:latest -f kubernetes/dockerfiles/spark/Dockerfile .

RUN set -ex && \
    apt-get update && \
    ln -s /lib /lib64 && \
    apt install -y bash tini libc6 libpam-modules krb5-user libnss3 procps openjdk-17-jre && \
    mkdir -p /opt/spark && \
    mkdir -p /opt/spark/examples && \
    mkdir -p /opt/spark/work-dir && \
    touch /opt/spark/RELEASE && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/*

COPY ${SPARK_HADOOP_ROOT}/spark/jars /opt/spark/jars
COPY ${SPARK_HADOOP_ROOT}/spark/bin /opt/spark/bin
COPY ${SPARK_HADOOP_ROOT}/spark/sbin /opt/spark/sbin
COPY ${SPARK_HADOOP_ROOT}/spark/kubernetes/dockerfiles/spark/entrypoint.sh /opt/
COPY ${SPARK_HADOOP_ROOT}/spark/kubernetes/dockerfiles/spark/decom.sh /opt/
COPY ${SPARK_HADOOP_ROOT}/spark/examples /opt/spark/examples
COPY ${SPARK_HADOOP_ROOT}/spark/kubernetes/tests /opt/spark/tests
COPY ${SPARK_HADOOP_ROOT}/spark/data /opt/spark/data

#YOY ARE TRYING TO SEE THE DIST CLASS PATH

ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64/"
ENV SPARK_HOME="/opt/spark"
ENV HADOOP_HOME="/opt/hadoop"
ENV PATH="$SPARK_HOME/bin:$HADOOP_HOME/bin:$PATH"

# Makes the `hadoop classpath` command also return aws classpaths
ENV HADOOP_OPTIONAL_TOOLS="hadoop-aws"

COPY ${SPARK_HADOOP_ROOT}/hadoop $HADOOP_HOME


WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir
RUN chmod a+x /opt/decom.sh

ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Specify the User that the actual main process will run as
USER ${spark_uid}