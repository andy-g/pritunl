# Based on https://github.com/goofball222/pritunl/blob/main/stable/Dockerfile

FROM alpine

ARG VERSION

ENV \
    DEBUG=false \
    GOPATH="/go" \
    GOCACHE="/tmp/gocache" \
    GO111MODULE=on \
    PRITUNL_OPTS= \
    REVERSE_PROXY=false \
    WIREGUARD=false

WORKDIR /opt/pritunl

COPY docker-files /

COPY . /tmp/pritunl-${VERSION}


RUN set -x \
    && apk add -q --no-cache --virtual .build-deps \
    cargo curl gcc git \
    go libffi-dev linux-headers make \
    musl-dev openssl-dev python3-dev py3-pip \
    rust \
    && apk add -q --no-cache \
    bash ca-certificates ipset iptables \
    ip6tables openssl openvpn procps \
    py3-dnspython py3-requests py3-setuptools tzdata \
    wireguard-tools \
    && pip3 install --upgrade pip \ 
    && go install github.com/pritunl/pritunl-dns@latest \
    && go install github.com/pritunl/pritunl-web@latest \
    && cp /go/bin/* /usr/bin

RUN set -x \
    && cd /tmp/pritunl-${VERSION} \
    && python3 setup.py build \
    && pip3 install -r requirements.txt \
    && mkdir -p /var/lib/pritunl \
    && python3 setup.py install \
    && apk del -q --purge .build-deps \
    && rm -rf /go /root/.cache/* /tmp/* /var/cache/apk/*

EXPOSE 80/tcp 443/tcp 1194/tcp 1194/udp 1195/udp 9700/tcp

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["pritunl"]
