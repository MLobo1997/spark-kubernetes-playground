FROM tmp/spark-image:stage-0 as build
FROM debian:bullseye-slim as main

COPY --from=build /opt/spark /opt/spark
COPY --from=build /opt/hadoop /opt/hadoop

RUN set -ex && \
    apt-get update && \
    ln -s /lib /lib64 && \
    apt install -y bash tini libc6 libpam-modules krb5-user libnss3 procps openjdk-17-jre && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/*

ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64/"
# Makes the `hadoop classpath` command also return aws classpaths
# TODO Move to hadoop-env.sh
ENV HADOOP_OPTIONAL_TOOLS="hadoop-aws"
ENV HADOOP_HOME="/opt/hadoop"
ENV SPARK_HOME="/opt/spark"
ENV PATH="$SPARK_HOME/bin:$HADOOP_HOME/bin:$PATH"

COPY custom-confs/* /opt/spark/conf/
COPY --from=build /opt/decom.sh /opt/decom.sh
COPY --from=build /opt/entrypoint.sh /opt/entrypoint.sh

WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir
RUN chmod a+x /opt/decom.sh

ENTRYPOINT [ "/opt/entrypoint.sh" ]

#TODO remove once tars are used
RUN mkdir /opt/spark/logs && \
    chown -R ${spark_uid}:root /opt/spark/logs

# Specify the User that the actual main process will run as
USER ${spark_uid}
