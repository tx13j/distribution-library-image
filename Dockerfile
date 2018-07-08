FROM golang:1.10-alpine3.7 as buildstage

ARG DOCKER_REGISTRY_VERSION=v2.6.2

RUN set -ex && \
    apk update && \
    apk add --no-cache --virtual .build-deps \
        ca-certificates \
        git \
        make \
    && \
    go get -u github.com/docker/distribution && \
    go get -u github.com/golang/lint/golint && \
    cd /go/src/github.com/docker/distribution && \
    git checkout $DOCKER_REGISTRY_VERSION && \
    make binaries && \
    apk del .build-deps && \
    rm -rf /var/cache/apk/* /var/tmp/* /tmp/*

FROM alpine:3.7

RUN set -ex \
    apk update && \
    apk add --no-cache \
        ca-certificates \
        apache2-utils \
    && \
    rm -rf /var/cache/apk/* /var/tmp/* /tmp/*

COPY --from=buildstage /go/src/github.com/docker/distribution/bin/registry /bin/registry
COPY ./registry/config-example.yml /etc/docker/registry/config.yml

VOLUME ["/var/lib/registry"]
EXPOSE 5000

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/etc/docker/registry/config.yml"]
