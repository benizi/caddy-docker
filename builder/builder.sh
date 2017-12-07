#!/bin/sh

: ${REPO=benizi}
VERSION=${VERSION:-"0.10.11"}

# caddy
git clone https://github.com/$REPO/caddy -b "v$VERSION" /go/src/github.com/$REPO/caddy \
    && cd /go/src/github.com/$REPO/caddy \
    && git checkout -b "v$VERSION"

# plugin helper
GOOS=linux GOARCH=amd64 go get -v github.com/benizi/caddyplug/caddyplug
alias caddyplug='GOOS=linux GOARCH=amd64 caddyplug'

# plugins
for plugin in $(echo $PLUGINS | tr "," " "); do \
    go get -v $(caddyplug package $plugin); \
    printf "package caddyhttp\nimport _ \"$(caddyplug package $plugin)\"" > \
        /go/src/github.com/$REPO/caddy/caddyhttp/$plugin.go ; \
    done

# builder dependency
git clone https://github.com/caddyserver/builds /go/src/github.com/caddyserver/builds

# build
cd /go/src/github.com/$REPO/caddy/caddy \
    && git checkout -f \
    && GOOS=linux GOARCH=amd64 go run build.go -goos=$GOOS -goarch=$GOARCH -goarm=$GOARM \
    && mkdir -p /install \
    && mv caddy /install

