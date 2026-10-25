ARG RUST_VERSION=1.99
ARG CARGO_BUILD_FEATURES=default
ARG RUST_RELEASE_MODE=debug

ARG BUILDER_IMAGE=lukemathwalker/cargo-chef:latest-rust-${RUST_VERSION}
ARG RUNNER_IMAGE=debian:trixie-slim

# Chef
FROM ${BUILDER_IMAGE} AS chef
WORKDIR /srv/pttbbs-lemmy

# Planner
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# Builder
FROM chef AS builder

ARG CARGO_BUILD_FEATURES
ARG RUST_RELEASE_MODE
ARG RUSTFLAGS
ARG CI_PIPELINE_EVENT

COPY --from=planner /srv/pttbbs-lemmy/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN if [ "${RUST_RELEASE_MODE}" = "release" ]; \
  then \
  cargo chef cook --recipe-path recipe.json --release --all-features; \
  else \
  cargo chef cook --recipe-path recipe.json; \
  fi

COPY . .

RUN if [ "${RUST_RELEASE_MODE}" = "release" ]; \
  then \
  cargo build --features "${CARGO_BUILD_FEATURES}" --release --all-features; \
  mv target/release/pttbbs-lemmy .; \
  else \
  cargo build --features "${CARGO_BUILD_FEATURES}"; \
  mv target/debug/pttbbs-lemmy .; \
  fi

# Runner
FROM ${RUNNER_IMAGE} AS runner

RUN apt update && apt install -y libssl-dev libpq-dev ca-certificates curl git

COPY --from=builder --chmod=0755 /srv/pttbbs-lemmy/pttbbs-lemmy /usr/local/bin

ENTRYPOINT ["pttbbs-lemmy"]
EXPOSE 8536
STOPSIGNAL SIGTERM
