# --- Stage 1: Builder (Native ARM64) ---
FROM debian:bookworm AS builder

# Install dependencies for native compilation
# Note: No 'crossbuild-essential' or ':arm64' suffixes needed anymore
RUN echo "deb http://deb.debian.org/debian bookworm main" > /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian bookworm-updates main" >> /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian-security bookworm-security main" >> /etc/apt/sources.list

RUN apt-get update && \
    apt-get install -y \
    build-essential \
    cmake \
    curl \
    git \
    libasound2-dev \
    libpulse-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Setup Rust environment
ENV PATH="/root/.cargo/bin/:${PATH}"
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain 1.85 -y && \
    cargo install bindgen-cli

WORKDIR /src
# We assume the context is prepared by GHA (source code present)
COPY . .

# Build the release binary natively
# We still use cache mounts to speed up rebuilds
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/src/target \
    cargo build --release \
    --no-default-features \
    --features "rustls-tls-webpki-roots alsa-backend with-libmdns" && \
    # Copy binary to a temporary location to separate it from the build cache
    cp target/release/librespot /tmp/librespot

# --- Stage 2: Runtime (Final Image) ---
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libasound2 \
    libpulse0 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Setup user
RUN groupadd -r librespot && useradd -r -g librespot -G audio librespot

# Copy artifact and script
COPY --from=builder /tmp/librespot /usr/local/bin/librespot
COPY docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

USER librespot
WORKDIR /var/lib/librespot

ENTRYPOINT ["/entrypoint.sh"]
