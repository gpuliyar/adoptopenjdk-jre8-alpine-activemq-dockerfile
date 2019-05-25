FROM adoptopenjdk/openjdk8:jre8u212-b03-alpine

ENV ACTIVEMQ_VERSION 5.14.5
ENV ACTIVEMQ apache-activemq-${ACTIVEMQ_VERSION}
ENV ACTIVEMQ_TCP=61616 ACTIVEMQ_AMQP=5672 ACTIVEMQ_STOMP=61613 ACTIVEMQ_MQTT=1883 ACTIVEMQ_WS=61614 ACTIVEMQ_UI=8161
ENV ACTIVEMQ_HOME /opt/activemq

COPY entrypoint.sh /

RUN set -ex; \
    \
    addgroup -S -g 1000 activemq; \
    adduser -S -D -s /sbin/nologin -G activemq -u 1000 activemq; \
    \
    apk --update add --no-cache --virtual build-dependencies gnupg; \
    apk add --no-cache bash; \
    \
    wget -q http://www.apache.org/dist/activemq/KEYS -O KEYS; \
    wget -q https://www.apache.org/dist/activemq/${ACTIVEMQ_VERSION}/${ACTIVEMQ}-bin.tar.gz.asc -O ${ACTIVEMQ}-bin.tar.gz.asc; \
    wget -q https://archive.apache.org/dist/activemq/${ACTIVEMQ_VERSION}/${ACTIVEMQ}-bin.tar.gz -O ${ACTIVEMQ}-bin.tar.gz; \
    \
    gpg --import KEYS; \
    gpg --verify ${ACTIVEMQ}-bin.tar.gz.asc ${ACTIVEMQ}-bin.tar.gz; \
    \
    tar xvz -f ${ACTIVEMQ}-bin.tar.gz -C /opt; \
    rm ${ACTIVEMQ}-bin.tar.gz; \
    \
    ln -s /opt/${ACTIVEMQ} ${ACTIVEMQ_HOME}; \
    \
    chown -R activemq:activemq /opt/${ACTIVEMQ}; \
    chown -h activemq:activemq ${ACTIVEMQ_HOME}; \
    chown -R activemq:activemq ${JAVA_HOME}; \
    chown activemq:activemq /entrypoint.sh; \
    \
    chmod +x /entrypoint.sh; \
    \
    apk del build-dependencies; \
    rm -rf /var/cache/apk/*;

VOLUME [ "/opt/activemq/data", "/opt/activemq/conf" ]

WORKDIR ${ACTIVEMQ_HOME}

EXPOSE ${ACTIVEMQ_TCP} ${ACTIVEMQ_AMQP} ${ACTIVEMQ_STOMP} ${ACTIVEMQ_MQTT} ${ACTIVEMQ_WS} ${ACTIVEMQ_UI}

USER activemq

ENTRYPOINT [ "/bin/sh", "-c", "bin/activemq" ]

CMD [ "console" ]
