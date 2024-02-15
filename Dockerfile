# syntax=docker/dockerfile:1

FROM golang:1.21-alpine AS build-stage
WORKDIR /go/src/app
COPY go.mod go.sum .
RUN --mount=type=cache,id=mod-cache,target=/go/pkg/mod \
    go mod download -x
COPY . .
RUN --mount=type=cache,id=mod-cache,target=/go/pkg/mod \
    set -ex; \
    CGO_ENABLED=0 go build -o /go/bin/app ./cmd/app; \
    CGO_ENABLED=0 go build -o /go/bin/healthcheck ./cmd/healthcheck

FROM gcr.io/distroless/static-debian12:nonroot AS production-stage
EXPOSE 8080
COPY --from=build-stage /go/bin/app /go/bin/healthcheck /
CMD ["/app"]
