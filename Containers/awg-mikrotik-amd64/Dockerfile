ARG ALPINE_VERSION=3.23
ARG GOLANG_VERSION=1.26.4
#Change ARCHITECTURE argument to "arm64" or "arm" or "amd64"
ARG ARCHITECTURE=amd64

#--------------------------------Builder--------------------------------

FROM golang:${GOLANG_VERSION}-alpine${ALPINE_VERSION} AS builder

RUN apk update && apk add --no-cache git make bash build-base linux-headers
RUN git clone https://github.com/amnezia-vpn/amneziawg-go.git
RUN git clone https://github.com/amnezia-vpn/amneziawg-tools.git
RUN cd /go/amneziawg-go && \
    GOOS=linux GOARCH=${ARCHITECTURE} make
RUN cd /go/amneziawg-tools/src && \
    GOOS=linux GOARCH=${ARCHITECTURE} make

#--------------------------------Image--------------------------------

FROM alpine:${ALPINE_VERSION}
RUN set -ex; \
	apk update && apk add --no-cache bash openrc nftables iproute2 openresolv  \
    && mkdir -p /etc/amnezia/amneziawg/

COPY --from=builder /go/amneziawg-go/amneziawg-go /usr/bin/amneziawg-go
COPY --from=builder /go/amneziawg-tools/src/wg /usr/bin/awg
COPY --from=builder /go/amneziawg-tools/src/wg-quick/linux.bash /usr/bin/awg-quick
COPY wireguard-fs /

RUN \
    sed -i 's/^\(tty\d\:\:\)/#\1/' /etc/inittab && \
    sed -i \
        -e 's/^#\?rc_env_allow=.*/rc_env_allow="\*"/' \
        -e 's/^#\?rc_sys=.*/rc_sys="docker"/' \
        /etc/rc.conf && \
    sed -i \
        -e 's/VSERVER/DOCKER/' \
        -e 's/checkpath -d "$RC_SVCDIR"/mkdir "$RC_SVCDIR"/' \
        /usr/libexec/rc/sh/init.sh && \
    rm \
        /etc/init.d/hwdrivers \
        /etc/init.d/machine-id
RUN    sed -i 's/cmd sysctl -q \(.*\?\)=\(.*\)/[[ "$(sysctl -n \1)" != "\2" ]] \&\& \0/' /usr/bin/awg-quick

RUN rc-update add nftables boot
RUN rc-update add wg-quick default

RUN echo -e " \n\
    net.ipv4.ip_forward = 1 \n\
	net.ipv6.conf.default.forwarding=1 \n\
	net.ipv6.conf.all.forwarding = 1 \n\ 
    " | sed -e 's/^\s\+//g' | tee -a /etc/sysctl.conf
	
RUN sed -i 's/^tty/#tty/' /etc/inittab
ENTRYPOINT ["/sbin/init"]

#https://hub.docker.com/_/golang
#https://hub.docker.com/_/alpine
#https://github.com/tailscale/tailscale/issues/10540