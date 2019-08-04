ARG ARCH=amd
ARG NODE_VERSION=10
ARG OS=alpine

FROM ${ARCH}/node:${NODE_VERSION}-${OS}

# Basic build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_REF
ARG NODE_RED_VERSION
LABEL org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.docker.dockerfile=".docker/Dockerfile.alpine" \
    org.label-schema.license="GNU" \
    org.label-schema.name="node-red" \
    org.label-schema.version=${BUILD_VERSION} \
    org.label-schema.description="Node-RED is a programming tool for wiring together hardware devices, APIs and online services in new and interesting ways." \
    org.label-schema.url="https://nodered.org" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/RaymondMouthaan/node-red-docker" \
    maintainer="Raymond M Mouthaan <raymondmmouthaan@gmail.com>"

# QEMU - Quick Emulation: Run operating systems for any machine, on any supported architecture.
ARG QEMU_ARCH=x86_64
COPY tmp/qemu-$QEMU_ARCH-static /usr/bin/qemu-$QEMU_ARCH-static

# Install Python 2 & RPi.GPIO (Python 2.7 will reach the end of its life on January 1st, 2020!)
ARG PYTHON_VERSION=0
RUN set -ex \
    && if [ ${PYTHON_VERSION} == "2" ]; then (echo "Installing Python 2 & RPi.GPIO" \
        && apk add --no-cache python py-pip \
        && apk add --no-cache --virtual build-dependencies gcc python-dev libc-dev \
        && pip install --upgrade pip \
        && pip install RPi.GPIO \
        && apk del build-dependencies); fi

# Install Python 3 & RPi.GPIO
RUN set -ex \
    && if [ ${PYTHON_VERSION} == "3" ]; then (echo "Installing Python 3 & RPi.GPIO" \
        && apk add --no-cache python3 \
        && apk add --no-cache --virtual build-dependencies gcc python3-dev libc-dev \
        && pip3 install --upgrade pip \
        && pip3 install RPi.GPIO \
        && apk del build-dependencies); fi

# Install tools, create node-red app and data dir, add user and set rights
RUN set -ex \
    && apk add --no-cache git openssh-client \
    && mkdir -p /usr/src/node-red /data \
    && adduser -h /usr/src/node-red -D -H node-red \
    && chown -R node-red:node-red /data \
    && chown -R node-red:node-red /usr/src/node-red

# Run as node-red user
USER node-red

# Set work directory
WORKDIR /usr/src/node-red

# package.json contains Node-RED NPM module and node dependencies
COPY package.json /usr/src/node-red/
RUN npm install

# Env variables
ENV NODE_RED_VERSION=$NODE_RED_VERSION
ENV FLOWS=flows.json
ENV NODE_PATH=/usr/src/node-red/node_modules:/data/node_modules

# User configuration directory volume
VOLUME ["/data"]

# Expose the listening port of node-red
EXPOSE 1880

ENTRYPOINT ["npm", "start", "--", "--userDir", "/data"]
