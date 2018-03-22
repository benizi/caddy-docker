FROM golang:1.10-alpine

RUN apk add --no-cache git gcc musl-dev

COPY builder.sh /build

RUN chmod +x /build

CMD ["/build"]
