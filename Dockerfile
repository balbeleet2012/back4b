# 阶段 1：构建
FROM golang:1.20-alpine AS builder
WORKDIR /app

# 核心修改：支持动态端口探测，适配 Back4App 的环境变量注入
RUN echo 'package main; \
import ("net/http"; "log"; "os"; "os/exec"); \
func main() { \
    // 优先获取平台的 PORT 环境变量，默认 fallback 到 8080 或 80 \
    port := os.Getenv("PORT"); \
    if port == "" { \
        port = "8080"; \
    } \
    \
    // 后台启动 HTTP 健康检查 \
    go func() { \
        http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) { \
            w.WriteHeader(200); \
            w.Write([]byte("OK")); \
        }); \
        log.Printf("Healthcheck server started on port :%s\n", port); \
        log.Fatal(http.ListenAndServe(":"+port, nil)); \
    }(); \
    \
    // 检查并执行实际的主程序 \
    if len(os.Args) < 2 { \
        log.Fatal("No command provided to execute."); \
    } \
    cmd := exec.Command(os.Args[1], os.Args[2:]...); \
    cmd.Stdout = os.Stdout; \
    cmd.Stderr = os.Stderr; \
    \
    log.Printf("Starting main process: %v\n", os.Args[1:]); \
    if err := cmd.Run(); err != nil { \
        log.Fatalf("Main process exited with error: %v", err); \
    } \
}' > main.go

RUN go build -o healthcheck main.go

# 阶段 2：运行
FROM netbirdio/netbird:0.71.3-rootless

USER root
COPY --from=builder /app/healthcheck /usr/local/bin/healthcheck
RUN chmod +x /usr/local/bin/healthcheck

# 暴露平台常用的默认端口
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/healthcheck"]
CMD ["sh", "-c", "/usr/local/bin/netbird-entrypoint.sh"]
