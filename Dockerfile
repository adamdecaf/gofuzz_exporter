FROM golang:1.14-alpine as builder
WORKDIR /go/src/github.com/adamdecaf/gofuzz_exporter
RUN apk add -U make
RUN adduser -D -g '' --shell /bin/false golang
COPY . .
ENV CGO_ENABLED=0
ENV GO111MODULE=on
RUN go mod download
RUN make build
USER golang

FROM scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /go/src/github.com/adamdecaf/gofuzz_exporter/bin/gofuzz_exporter_linux /bin/gofuzz_exporter
COPY --from=builder /etc/passwd /etc/passwd
USER golang
EXPOSE 10000
ENTRYPOINT ["/bin/gofuzz_exporter"]
