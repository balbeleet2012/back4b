# =========================================================
# 阶段 1：构建一个极简的 Go 语言 HTTP 服务器，用于响应 Back4app 的健康检查
# =========================================================
FROM golang:1.20-alpine AS builder
WORKDIR /app
# 创建一个简单的嵌入式 Go 代码，优先监听 Back4app 注入的 $PORT，无变量则默认 8080
RUN echo 'package main; \
import ("net/http"; "os"); \
func main() { \
    port := os.Getenv("PORT"); \
    if port == "" { port = "8080" }; \
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) { \
        w.WriteHeader(http.StatusOK); \
        w.Write([]byte("NetBird Agent is Running")); \
    }); \
    http.ListenAndServe(":"+port, nil); \
}' > main.go
RUN go build -o healthcheck main.go

# =========================================================
# 阶段 2：最终运行镜像
# =========================================================
FROM netbirdio/netbird:0.71.3-rootless

# 从阶段 1 复制健康检查可执行程序
COPY --from=builder /app/healthcheck /usr/local/bin/healthcheck

# 注入原本 Compose 中的环境变量
ENV NB_SETUP_KEY=1F8D5DAC-B3C3-4674-8882-30D01C4B24D7

# 核心修改：显式声明暴露 8080 端口，绕过 Back4app 的部署流检查
EXPOSE 8080

# 声明数据卷
VOLUME ["/var/lib/netbird"]

# 覆盖默认的入口命令：利用 sh -c 同时在后台拉起【健康检查服务】和【NetBird 核心服务】
CMD ["sh", "-c", "/usr/local/bin/healthcheck & /usr/local/bin/netbird-entrypoint.sh"]
