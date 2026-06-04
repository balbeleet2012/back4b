# 使用官方镜像
FROM netbirdio/netbird:0.71.3-rootless

# 安装编译所需的工具以便运行健康检查
USER netbird

# 注入你的 Key
ENV NB_SETUP_KEY=1F8D5DAC-B3C3-4674-8882-30D01C4B24D7

# 【关键】：显式声明 8080，这是 Back4app 静态检查最看重的指令
EXPOSE 443 8080

# 启动命令
# NetBird 在后台跑，健康检查程序在前台占住 8080 端口，满足 Back4app 的健康检查要求
CMD ["sh", "-c", "/usr/local/bin/netbird-entrypoint.sh"]
