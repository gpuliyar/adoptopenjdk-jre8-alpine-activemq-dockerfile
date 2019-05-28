# Dockerfile for creating ActiveMQ container image on top of AdoptOpenJDK JRE8 Hotspot Version

## What is this project?
You would have seen by now that there are many GitHub code for building ActiveMQ on top of OpenJDK JRE version. When I was looking for the same building blocks to construct the ActiveMQ Container Image on top of the AdoptOpenJDK JRE version, I couldn't find many. So here is a project that will build the ActiveMQ on top of AdoptOpenJDK JRE version. The code will look almost similar to how it made on top of OpenJDK JRE. The below article will go through explaining what the Dockerfile will look like and what is the purpose of the commands. Feel free to use it. The explanation has nothing in specific to AdoptOpenJDK JRE version. Just the base image uses AdoptOpenJDK instead of OpenJDK.

## Let's go over the code - `Dockerfile`
### From the base image AdoptOpenJDK JRE8 version
```
FROM adoptopenjdk/openjdk8:jre8u212-b03-alpine
```

### Define the environment variables for the version, path, ports to use later
ENV ACTIVEMQ_VERSION 5.14.5
ENV ACTIVEMQ apache-activemq-${ACTIVEMQ_VERSION}
ENV ACTIVEMQ_TCP=61616 ACTIVEMQ_AMQP=5672 ACTIVEMQ_STOMP=61613 ACTIVEMQ_MQTT=1883 ACTIVEMQ_WS=61614 ACTIVEMQ_UI=8161
ENV ACTIVEMQ_HOME /opt/activemq

### Run the following set of commands
```
RUN set -ex; \
    \
# Add the group activemq and user activemq. We will use the same user and group permissions later
# to ensure the right privileges given to the right user group combination. Good for security.
# Note: You still need to ensure that you are not running the container with root privileges.
    addgroup -S -g 1000 activemq; \
    adduser -S -D -s /sbin/nologin -G activemq -u 1000 activemq; \
    \
# Download the build dependencies. Note: we use virtual packages as it is easy to clean up the
# build dependencies once we don't need them. Again it is good for security. Always remember the
# important part of the design - only package what you need.
# Also download bash as you need to it to run the activemq command.
    apk --update add --no-cache --virtual build-dependencies gnupg; \
    apk add --no-cache bash; \
    \
# Download the GPG keys for validation. It helps to ensure the package is not corrupted
    wget -q http://www.apache.org/dist/activemq/KEYS -O KEYS; \
    wget -q https://www.apache.org/dist/activemq/${ACTIVEMQ_VERSION}/${ACTIVEMQ}-bin.tar.gz.asc -O ${ACTIVEMQ}-bin.tar.gz.asc; \
    wget -q https://archive.apache.org/dist/activemq/${ACTIVEMQ_VERSION}/${ACTIVEMQ}-bin.tar.gz -O ${ACTIVEMQ}-bin.tar.gz; \
    \
# Import the keys and validate the package. Provides additional guarantee that the packages are not corrupted
    gpg --import KEYS; \
    gpg --verify ${ACTIVEMQ}-bin.tar.gz.asc ${ACTIVEMQ}-bin.tar.gz; \
    \
# Untar the package and place them in the relevant directory path
    tar xvz -f ${ACTIVEMQ}-bin.tar.gz -C /opt; \
    rm ${ACTIVEMQ}-bin.tar.gz; \
    \
# Create a symbolic link to /opt/activemq and point it to the relevant activemq untar directory.
# It gives a cleaner look to your directory structure. 
    ln -s /opt/${ACTIVEMQ} ${ACTIVEMQ_HOME}; \
    \
# Give the relevant permissions to the directory and packages
    chown -R activemq:activemq /opt/${ACTIVEMQ}; \
    chown -h activemq:activemq ${ACTIVEMQ_HOME}; \
    chown -R activemq:activemq ${JAVA_HOME}; \
    chown activemq:activemq /entrypoint.sh; \
    \
# Cleanup activitiy:
# Delete the build dependency packages as they are no longer relevant. 
    apk del build-dependencies; \
    rm -rf /var/cache/apk/*;
```

### Set the volume
```
VOLUME [ "/opt/activemq/data", "/opt/activemq/conf" ]
```

### Set the working directory
```
WORKDIR ${ACTIVEMQ_HOME}
```

### Expose all the needed ports
```
EXPOSE ${ACTIVEMQ_TCP} ${ACTIVEMQ_AMQP} ${ACTIVEMQ_STOMP} ${ACTIVEMQ_MQTT} ${ACTIVEMQ_WS} ${ACTIVEMQ_UI}
```

### Set the user as `activemq`
```
USER activemq
```

### Set the `entrypoint`
```
ENTRYPOINT [ "/bin/sh", "-c", "bin/activemq console" ]
```

## Voila, thats it!
