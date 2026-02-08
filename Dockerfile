# --- Base Stage (Shared setup) ---

FROM debian:bookworm AS base

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
    apt-get install -y \
    build-essential \
    cmake \
    curl \
    git \
    libasound2-dev \
    libpulse-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/root/.cargo/bin/:${PATH}"
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain 1.85 -y && \
    cargo install cargo-chef

WORKDIR /src

# --- Stage 1: Planner (Calculate recipe) ---

FROM base AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# --- Stage 2: Builder (Compile dependencies) ---

FROM base AS builder
COPY --from=planner /src/recipe.json recipe.json
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/src/target \
    cargo chef cook --release --recipe-path recipe.json \
    --no-default-features \
    --features "rustls-tls-webpki-roots alsa-backend with-libmdns"

# --- Stage 3: Compiler (Compileer source code) ---

COPY . .
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/src/target \
    cargo build --release \
    --no-default-features \
    --features "rustls-tls-webpki-roots alsa-backend with-libmdns" && \
    cp target/release/librespot /tmp/librespot

# --- Stage 4: Runtime (Final Image) ---

FROM debian:bookworm-slim

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    libasound2 \
    libpulse0 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r librespot && useradd -r -g librespot -G audio librespot

COPY --from=builder /tmp/librespot /usr/local/bin/librespot
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER librespot
WORKDIR /var/lib/librespot

ENTRYPOINT ["/entrypoint.sh"]
