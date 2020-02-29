VERSION := $(shell grep -Eo '(v[0-9]+[\.][0-9]+[\.][0-9]+(-[a-zA-Z0-9]*)?)' version.go)

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
