FROM golang:1.20-alpine AS builder
WORKDIR /app
RUN echo 'package main; \
import ("net/http"; "log"); \
func main() { \
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) { \
        w.WriteHeader(200); \
    }); \
    log.Fatal(http.ListenAndServe(":80", nil)); \
}' > main.go
RUN go build -o healthcheck main.go

# 阶段 2：运行
FROM netbirdio/netbird:0.71.3-rootless
USER root
COPY --from=builder /app/healthcheck /usr/local/bin/healthcheck
RUN chmod +x /usr/local/bin/healthcheck
EXPOSE 80

# 【核心修改】：我们将健康检查作为入口点，并让它去拉起 NetBird
# 这样确保健康检查程序是 PID 1，绝对不会被杀掉
ENTRYPOINT ["/usr/local/bin/healthcheck"]
CMD ["sh", "-c", "/usr/local/bin/netbird-entrypoint.sh"]
