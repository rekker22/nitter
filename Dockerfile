# syntax=docker/dockerfile:1.2

FROM nimlang/nim:2.2.0-alpine-regular as build
LABEL maintainer="setenforce@protonmail.com"

RUN apk --no-cache add libsass-dev pcre

WORKDIR /src/nitter

COPY nitter.nimble ./
RUN nimble install -y --depsOnly

COPY . ./
RUN nimble build -d:danger -d:lto -d:strip --mm:refc \
    && nimble scss \
    && nimble md

# Final image
FROM alpine:latest
WORKDIR /src/
RUN apk --no-cache add pcre ca-certificates redis

# Copy Nitter binary & resources
COPY --from=build /src/nitter/nitter ./nitter
COPY --from=build /src/nitter/public ./public

RUN --mount=type=secret,id=nitter_conf,dst=/etc/secrets/nitter.conf \
    --mount=type=secret,id=sessions_jsonl,dst=/etc/secrets/sessions.jsonl \
    cp /etc/secrets/nitter.conf ./nitter.conf && \
    cp /etc/secrets/sessions.jsonl ./sessions.jsonl

RUN ls -l /src/ && cat /src/nitter.conf

EXPOSE 8080

# Create non-root user
RUN adduser -h /src/ -D -s /bin/sh nitter
USER nitter

CMD redis-server --daemonize yes && ./nitter
