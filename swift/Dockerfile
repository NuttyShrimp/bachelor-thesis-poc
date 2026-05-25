# ================================
# Build image
# ================================
FROM swift:6.3-bookworm AS build

# Install OS updates
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libjemalloc-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# First just resolve dependencies.
# This creates a cached layer that can be reused
# as long as your Package.swift/Package.resolved
# files do not change.
COPY ./Package.* ./
RUN --mount=type=cache,target=/build/.build swift package resolve

# Copy entire repo into container
COPY . .

ARG SWIFT_BUILD_FLAGS=""

# Build the application, with optimizations, with static linking, using jemalloc, and stage the artifacts
RUN --mount=type=cache,target=/build/.build \
    swift build -c release \
        --product "Bap" \
        --static-swift-stdlib \
        -Xlinker -ljemalloc \
        $SWIFT_BUILD_FLAGS \
    && mkdir -p /staging \
    && cp "$(swift build -c release $SWIFT_BUILD_FLAGS --show-bin-path)/Bap" /staging/ \
    && cp "/usr/libexec/swift/linux/swift-backtrace-static" /staging/ \
    && find -L "$(swift build -c release $SWIFT_BUILD_FLAGS --show-bin-path)/" -regex '.*\.resources$' -exec cp -Ra {} /staging/ \; \
    && ([ -d /build/public ] && { cp -Ra /build/public /staging/public && chmod -R a-w /staging/public; } || true)

# Switch to the staging area
WORKDIR /staging

# ================================
# Run image
# ================================
# FROM ubuntu:noble
FROM debian:trixie

# Make sure all system packages are up to date, and install only essential packages.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y \
      libjemalloc2 \
      ca-certificates \
      tzdata \
      libxlsxwriter8 \
      weasyprint \
      curl \
      fontconfig libfontconfig1 libjpeg62-turbo libxrender1 xfonts-75dpi xfonts-base libxext6 \
    && rm -r /var/lib/apt/lists/*

RUN curl "https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb" -L -o "/tmp/wkhtmltopdf.deb"

RUN apt -q install -y "/tmp/wkhtmltopdf.deb"

# Create a hummingbird user and group with /app as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app hummingbird

# Switch to the new home directory
WORKDIR /app

# Copy built executable and any staged resources from builder
COPY --from=build --chown=hummingbird:hummingbird /staging /app

# Provide configuration needed by the built-in crash reporter and some sensible default behaviors.
ENV SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all,images=all,interactive=no,swift-backtrace=./swift-backtrace-static

# Tune jemalloc to return unused pages to the OS more aggressively.
ENV MALLOC_CONF=background_thread:true,dirty_decay_ms:500,muzzy_decay_ms:500

# Ensure all further commands run as the hummingbird user
USER hummingbird:hummingbird

# Let Docker bind to port 8080
EXPOSE 8080

# Start the Hummingbird service when the image is run, default to listening on 8080 in production environment
ENTRYPOINT ["./Bap"]
CMD ["--http-host", "0.0.0.0", "--http-port", "8080"]
