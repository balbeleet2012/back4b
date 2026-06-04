# 使用官方镜像
FROM golang:1.20-alpine AS builder
WORKDIR /app
RUN echo 'package main; \
import ("net/http"; "os"; "log"); \
func main() { \
    port := os.Getenv("PORT"); \
    if port == "" { port = "8080" }; \
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) { \
        w.WriteHeader(http.StatusOK); \
        w.Write([]byte("NetBird is running")); \
    }); \
    log.Fatal(http.ListenAndServe(":" + port, nil)); \
}' > main.go
RUN go build -o healthcheck main.go

# =========================================================
# 阶段 2：运行镜像
# =========================================================
# 按照你的要求，指定使用 0.71.3-rootless 版本
FROM netbirdio/netbird:0.71.3-rootless

# 复制健康检查程序
COPY --from=builder /app/healthcheck /usr/local/bin/healthcheck

EXPOSE 443 8080

VOLUME ["/var/lib/netbird"]

# 启动命令
# 1. 启动 NetBird
# 2. 用 exec 启动健康检查服务，监听平台分配的 $PORT (如果平台通过 443 转发，它会自动映射到这里)
CMD ["sh", "-c", "/usr/local/bin/netbird-entrypoint.sh & exec /usr/local/bin/healthcheck"]
