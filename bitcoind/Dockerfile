FROM debian:bookworm-slim

ENV BITCOIN_VERSION=26.0

RUN apt-get update && apt-get install -y \
    wget ca-certificates tini \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m bitcoin

RUN wget https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz \
    && tar -xzf bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz \
    && install -m 0755 -o root -g root -t /usr/local/bin bitcoin-${BITCOIN_VERSION}/bin/* \
    && rm -rf bitcoin-${BITCOIN_VERSION}*

COPY bitcoin.conf /home/bitcoin/.bitcoin/bitcoin.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && chown -R bitcoin:bitcoin /home/bitcoin

USER bitcoin

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]