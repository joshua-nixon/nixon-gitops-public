FROM alpine/helm:4

WORKDIR /app

COPY --chmod=755 main.sh /app/main.sh

RUN apk add --no-cache jq

ENTRYPOINT ["/app/main.sh"]