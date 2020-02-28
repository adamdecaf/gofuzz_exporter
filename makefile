VERSION := $(shell grep -Eo '(\d\.\d\.\d)(-dev)?' version.go | head -n1)

.PHONY: build deps docker

build:
	go fmt ./...
	go vet ./...
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -o bin/gofuzz_exporter_darwin .
	CGO_ENABLED=0 GOOS=linux  GOARCH=amd64 go build -o bin/gofuzz_exporter_linux .

docker: build
	docker build --pull -t adamdecaf/gofuzz_exporter:$(VERSION) -f Dockerfile .

run:
	docker run -p 10000:10000 adamdecaf/gofuzz_exporter:$(VERSION)

release-push:
	docker push adamdecaf/gofuzz_exporter:$(VERSION)

test:
	go test -v ./...