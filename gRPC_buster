FROM golang:buster as build

RUN apt update && apt install -y unzip dos2unix \
 && wget https://github.com/protocolbuffers/protobuf/releases/download/v3.9.1/protoc-3.9.1-linux-x86_64.zip -O protoc.zip \
 && unzip protoc.zip -d /usr/local \
 && go get -u google.golang.org/grpc \
 && go get -u github.com/golang/protobuf/protoc-gen-go
