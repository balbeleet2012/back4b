# 使用官方镜像
FROM netbirdio/netbird:0.71.3-rootless

# 安装编译所需的工具以便运行健康检查
USER netbird
EXPOSE 443 8080

# 启动命令
# NetBird 在后台跑，健康检查程序在前台占住 8080 端口，满足 Back4app 的健康检查要求
CMD ["sh", "-c", "/usr/local/bin/netbird-entrypoint.sh"]
