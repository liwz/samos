# skycoin build binaries
# reference https://github.com/samoslab/samos
FROM golang:1.9-alpine AS build-go

COPY . $GOPATH/src/github.com/samoslab/samos

RUN cd $GOPATH/src/github.com/samoslab/samos && \
  CGO_ENABLED=0 GOOS=linux go install -a -installsuffix cgo ./...


# skycoin gui
FROM node:8.9 AS build-node

COPY . /skycoin

# `unsafe` flag used as work around to prevent infinite loop in Docker
# see https://github.com/nodejs/node-gyp/issues/1236
RUN npm install -g --unsafe @angular/cli && \
    cd /skycoin/src/gui/static && \
    yarn && \
    npm run build


# skycoin image
FROM alpine:3.7

ENV COIN="skycoin" \
    RPC_ADDR="0.0.0.0:8650" \
    DATA_DIR="/data/.$COIN" \
    WALLET_DIR="/wallet" \
    WALLET_NAME="$COIN_cli.wlt"

RUN adduser -D skycoin

USER skycoin

# copy binaries
COPY --from=build-go /go/bin/* /usr/bin/

# copy gui
COPY --from=build-node /skycoin/src/gui/static /usr/local/skycoin/src/gui/static

# volumes
VOLUME $WALLET_DIR
VOLUME $DATA_DIR

EXPOSE 8858 8640 8650

WORKDIR /usr/local/skycoin

CMD ["skycoin", "--web-interface-addr=0.0.0.0"]
