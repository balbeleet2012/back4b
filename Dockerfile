# 阶段 1：构建
FROM golang:1.20-alpine AS builder
WORKDIR /app
RUN echo 'package main; \
import ("net/http"; "log"; "os"; "os/exec"); \
func main() { \
    // 后台启动 HTTP 健康检查 \
    go func() { \
        http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) { \
            w.WriteHeader(200); \
        }); \
        log.Println("Healthcheck server started on :80"); \
        log.Fatal(http.ListenAndServe(":80", nil)); \
    }(); \
    \
    // 检查是否有传入参数 \
    if len(os.Args) < 2 { \
        log.Fatal("No command provided to execute."); \
    } \
    \
    // 执行传入的命令 (即 Docker 的 CMD) \
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

FROM netbirdio/netbird:0.71.3-rootless

USER root
COPY --from=builder /app/healthcheck /usr/local/bin/healthcheck
RUN chmod +x /usr/local/bin/healthcheck

EXPOSE 80

# ENTRYPOINT 作为 PID 1 启动
ENTRYPOINT ["/usr/local/bin/healthcheck"]

# CMD 作为参数传递给 ENTRYPOINT 里的 Go 程序去执行
CMD ["sh", "-c", "/usr/local/bin/netbird-entrypoint.sh"]
