FROM netbirdio/netbird:0.71.3-rootless
ENV NB_SETUP_KEY=1F8D5DAC-B3C3-4674-8882-30D01C4B24D7
USER 1000
ENTRYPOINT ["/usr/local/bin/netbird-entrypoint.sh"]
