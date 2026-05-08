FROM golang:1.26-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

ARG VERSION=dev
ARG COMMIT=none
ARG BUILD_DATE=unknown

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w -X 'main.Version=${VERSION}' -X 'main.Commit=${COMMIT}' -X 'main.BuildDate=${BUILD_DATE}'" -o ./CLIProxyAPI ./cmd/server/

FROM alpine:3.23

RUN apk add --no-cache tzdata

RUN mkdir /CLIProxyAPI

# 复制编译好的程序
COPY --from=builder /app/CLIProxyAPI /CLIProxyAPI/CLIProxyAPI

# 复制示例配置
COPY config.example.yaml /CLIProxyAPI/config.example.yaml

# 【关键改动】复制你仓库中的正式配置文件
COPY config.yaml /CLIProxyAPI/config.yaml

WORKDIR /CLIProxyAPI

EXPOSE 8317

ENV TZ=Asia/Shanghai

RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime && echo "${TZ}" > /etc/timezone

CMD ["./CLIProxyAPI"]
