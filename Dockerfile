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
COPY --from=build /etc/secrets/nitter.conf ./nitter.conf
COPY --from=build /etc/secrets/sessions.jsonl ./sessions.jsonl
COPY --from=build /src/nitter/public ./public

EXPOSE 8080

# Create non-root user
RUN adduser -h /src/ -D -s /bin/sh nitter
USER nitter

CMD redis-server --daemonize yes && ./nitter
