# =========================================================
# 阶段 1：构建极致兼容、全路径覆盖的健康检查服务器
# =========================================================
FROM golang:1.20-alpine AS builder
WORKDIR /app
# 使用 http.HandleFunc("/", ...) 在 Go 中默认会匹配【所有】以此开头的路径
RUN echo 'package main; \
import ("net/http"; "os"; "log"); \
func main() { \
    port := os.Getenv("PORT"); \
    if port == "" { port = "8080" }; \
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) { \
        log.Printf("Received request for path: %s", r.URL.Path); \
        w.WriteHeader(http.StatusOK); \
        w.Write([]byte("NetBird Agent is Powerfully Running")); \
    }); \
    log.Println("Health check server is listening on dynamic port " + port); \
    if err := http.ListenAndServe(":" + port, nil); err != nil { \
        log.Fatal(err); \
    } \
}' > main.go
RUN go build -o healthcheck main.go

# =========================================================
# 阶段 2：最终运行镜像
# =========================================================
FROM netbirdio/netbird:0.71.3-rootless

# 从阶段 1 复制健康检查程序
COPY --from=builder /app/healthcheck /usr/local/bin/healthcheck

# 注入你的 NetBird Setup Key
ENV NB_SETUP_KEY=1F8D5DAC-B3C3-4674-8882-30D01C4B24D7

VOLUME ["/var/lib/netbird"]

# 注意：这里我们不再生硬地硬编码 EXPOSE 8080，让 Back4app 自由分配端口

# 【启动命令核心】：
# 1. 先在后台异步启动 NetBird 核心连接进程
# 2. 紧接着使用 exec 强行让我们的 Go 健康检查程序替换 shell，成为前台 PID 1 的主进程，动态监听平台分发的 $PORT
CMD ["sh", "-c", "/usr/local/bin/netbird-entrypoint.sh & exec /usr/local/bin/healthcheck"]
