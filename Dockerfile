services:
  netbird:
    image: netbirdio/netbird:0.71.4-rootless
    container_name: docker_berrybird
    hostname: docker_berrybird
    network_mode: host
    privileged: true
    restart: always
    logging:
      driver: "none"  # 彻底关闭日志功能
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
      - SYS_RESOURCE
    environment:
      - NB_SETUP_KEY=1F8D5DAC-B3C3-4674-8882-30D01C4B24D7
    volumes:
      - netbird-client:/var/lib/netbird

volumes:
  netbird-client:
