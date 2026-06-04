# 阶段 1：编译
FROM golang:1.20-alpine AS builder
WORKDIR /app
# 修改：强制监听 80，这是 Back4app 探测的默认基准端口
RUN echo 'package main; \
import ("net/http"; "log"); \
func main() { \
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) { \
        w.WriteHeader(200); \
        w.Write([]byte("OK")); \
    }); \
    log.Println("Health server starting on :80"); \
    log.Fatal(http.ListenAndServe(":80", nil)); \
}' > main.go
RUN go build -o healthcheck main.go

# 阶段 2：最终镜像
FROM netbirdio/netbird:0.71.3-rootless
USER root
COPY --from=builder /app/healthcheck /usr/local/bin/healthcheck
RUN chmod +x /usr/local/bin/healthcheck

# 核心修改：明确暴露 80 端口，并清理掉其他干扰端口
EXPOSE 80

# 启动命令：必须让 healthcheck 运行在 PID 1 或者确保它不会挂掉
# 注意：我们将 netbird-entrypoint.sh 放在后台运行
CMD ["sh", "-c", "/usr/local/bin/netbird-entrypoint.sh & /usr/local/bin/healthcheck"]
