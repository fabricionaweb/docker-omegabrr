# syntax=docker/dockerfile:1-labs
FROM public.ecr.aws/docker/library/alpine:3.19 AS base
ENV TZ=UTC
WORKDIR /src

# source stage =================================================================
FROM base AS source

# get and extract source from git
ARG BRANCH
ARG VERSION
ADD https://github.com/autobrr/omegabrr.git#${BRANCH:-v$VERSION} ./

# build stage ==================================================================
FROM base AS build-app
ENV CGO_ENABLED=0

# dependencies
RUN apk add --no-cache git && \
    apk add --no-cache go --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community

# build dependencies
COPY --from=source /src/go.mod /src/go.sum ./
RUN go mod download

# build app
COPY --from=source /src ./
ARG VERSION
ARG COMMIT=$VERSION
RUN mkdir /build && \
    go build -trimpath -ldflags "-s -w \
        -X buildinfo.Version=$VERSION \
        -X buildinfo.Commit=$COMMIT \
        -X buildinfo.Date=$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        -o /build/ ./cmd/...

# runtime stage ================================================================
FROM base

ENV S6_VERBOSITY=0 S6_BEHAVIOUR_IF_STAGE2_FAILS=2 PUID=65534 PGID=65534
WORKDIR /config
VOLUME /config
EXPOSE 7441

# copy files
COPY --from=build-app /build /app
COPY ./rootfs/. /

# runtime dependencies
RUN apk add --no-cache tzdata s6-overlay curl

# run using s6-overlay
ENTRYPOINT ["/entrypoint.sh"]
