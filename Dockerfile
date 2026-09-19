# syntax=docker/dockerfile:1

FROM debian:bookworm AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/var/cache/debconf \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    git \
    libasound2-dev \
    libclang-dev \
    libpulse0 \
    pkg-config \
    ca-certificates

ENV PATH="/root/.cargo/bin/:${PATH}"
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain 1.85 -y && \
    rustup target add aarch64-unknown-linux-gnu && \
    cargo install bindgen-cli && \
    mkdir /.cargo && \
    echo '[target.aarch64-unknown-linux-gnu]\nlinker = "aarch64-linux-gnu-gcc"' > /.cargo/config

ENV CARGO_TARGET_DIR=/build
ENV CARGO_HOME=/build/cache
ENV PKG_CONFIG_PATH_aarch64-unknown-linux-gnu=/usr/lib/aarch64-linux-gnu/pkgconfig/

WORKDIR /src

RUN git clone https://github.com/librespot-org/librespot.git .

RUN cargo build --release --target aarch64-unknown-linux-gnu --no-default-features --features "alsa-backend with-libmdns rustls-tls-webpki-roots"

###

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/var/cache/debconf \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    libasound2 \
    libpulse0 \
    ca-certificates

RUN groupadd -r librespot && useradd -r -g librespot -G audio librespot

COPY --from=builder /build/aarch64-unknown-linux-gnu/release/librespot /usr/local/bin/librespot
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER librespot
WORKDIR /var/lib/librespot

ENTRYPOINT ["/entrypoint.sh"]
