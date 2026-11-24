# Repository Guidelines

## Project Overview
`github.com/Ptt-official-app/pttbbs-lemmy`: small Rust (edition 2024, `rust-version` 1.99) actix-web service built on top of [Lemmy](https://github.com/LemmyNet/lemmy) crates. It is a workaround so that `pttbbs-backend` can access Lemmy authentication: a caller with an admin JWT can obtain a login JWT for any user via `POST /api/v4/pttbbs-lemmy/token`. License AGPL-3.0. Workspace version is in the root `Cargo.toml` (`[workspace.package]`) and must match the image tag in `docker/docker-compose.tmpl.yaml`.

## Architecture & Data Flow
Client -> actix-web (`crates/server`: CORS, logging, compression, idempotency, `SessionMiddleware`, optional prometheus) -> `pttbbs_routes::config` (`crates/api/routes`, scope `/api/v4`, `RateLimit::message()`) -> `pttbbs_api::get_token` (`crates/api/api`).
- `get_token` extracts `LocalUserView` (the caller, authenticated by Lemmy's session middleware), requires `is_admin`, looks up the target with `LocalUserView::find_by_email_or_name`, and returns `LoginResponse { jwt }` from `Claims::generate`.
- Startup (`start_server`): temporary 503 "Lemmy is currently starting" server -> `build_db_pool` -> `Secret::init` -> `setup_local_site` (creates the site/admin from the `setup` config block) -> `LemmyContext::create` -> real HTTP server; graceful shutdown on SIGINT/SIGTERM.
- Settings come from `lemmy_utils::settings::SETTINGS`, read from the file named by `LEMMY_CONFIG_LOCATION`.
- The stack runs two processes against one Postgres: stock Lemmy (port 8536, runs DB migrations) and `pttbbs-lemmy` (port 8537).

## Key Directories
- `crates/server/` binary `pttbbs-lemmy` (`src/main.rs` logging init, `src/lib.rs` server setup)
- `crates/api/api/` request types and handlers (`get_token.rs`)
- `crates/api/routes/` route registration
- `config/` Lemmy-style hjson configs: `config.*.hjson` for pttbbs-lemmy, `lemmy.*.hjson` for the Lemmy container; `*.dev.*` for local dev, `*.tmpl.*` templates
- `docker/` `Dockerfile` (cargo-chef multi-stage build) and compose files (`docker-compose.dev.yaml`, `docker-compose.tmpl.yaml`)
- `scripts/` docker build/deploy/compose helpers and getting-started start/stop scripts
- `lemmy/`, `lemmy-ui/` are git submodules (LemmyNet): do not edit. Root `Cargo.toml` lists `lemmy/crates/*` as workspace members and path dependencies.

## Development Commands
```
git submodule update --init --recursive   # required before any cargo command
cargo build                               # builds all workspace members incl. lemmy crates
cargo run --bin pttbbs-lemmy              # needs LEMMY_CONFIG_LOCATION and a reachable Postgres
cargo fmt                                 # .rustfmt.toml (lemmy/ ignored)
cargo clippy --workspace                  # lints configured in [workspace.lints]
taplo fmt                                 # .taplo.toml, excludes lemmy/**
./scripts/lemmy_docker_build_all.sh       # builds docker-lemmy:latest and docker-lemmy-ui:latest from submodules
./scripts/start-getting-started.sh        # docker compose dev stack + cargo run with config/config.dev.hjson
./scripts/stop-getting-started.sh         # docker compose dev down
./scripts/docker_build.sh                 # docker image <dir>:<branch-or-tag>
./scripts/docker_deploy.sh                # multi-arch buildx push to pttofficialapps/<dir>:<branch-or-tag>
```
For the template compose stack, copy `config/*.tmpl.hjson` to `config/config.hjson` / `config/lemmy.hjson` and `docker/docker-compose.tmpl.yaml` to `docker/docker-compose.yaml` (these target files are git-ignored), then use `scripts/docker-compose-up.sh` / `docker-compose-down.sh`.

## Code Conventions & Common Patterns
- Handler shape (see `crates/api/api/src/get_token.rs`): request struct deriving `Serialize/Deserialize` with `#[cfg_attr(feature = "ts-rs", ...)]`, async fn taking `Json<T>`, `HttpRequest`, `Data<LemmyContext>`, `LocalUserView`, returning `LemmyResult<Json<...>>`. Register in `crates/api/routes/src/lib.rs` under the `/api/v4/pttbbs-lemmy` scope.
- Reuse Lemmy types/utilities (`lemmy_api_utils`, `lemmy_db_views_*`, `lemmy_utils::error::LemmyResult`) rather than reimplementing them.
- Strict clippy in `[workspace.lints.clippy]`: `unwrap_used`, `expect_used`, `indexing_slicing`, `as_conversions`, `unreachable`, `allow_attributes` etc. are denied; `unsafe_code` is forbidden. Each crate must opt in with `[lints] workspace = true`.
- rustfmt: crate-level import granularity, `group_imports = "One"`, comments wrapped at 100 columns.
- Workspace dependencies are declared once in the root `Cargo.toml` and referenced with `{ workspace = true }`.
- Server setup in `crates/server/src/lib.rs` mirrors `lemmy/crates/server`; keep it in sync when bumping the submodule.

## Important Files
`Cargo.toml`, `crates/server/src/lib.rs`, `crates/api/api/src/get_token.rs`, `crates/api/routes/src/lib.rs`, `config/*.hjson`, `docker/Dockerfile`, `docker/docker-compose.*.yaml`, `.rustfmt.toml`, `.taplo.toml`, `.env.tmpl`, `README.md`.

## Runtime/Tooling Preferences
- Rust toolchain >= 1.99 (`rust-version`; `docker/Dockerfile` uses `lukemathwalker/cargo-chef` with `RUST_VERSION=1.99`); note `lemmy/rust-toolchain.toml` pins its own channel.
- Needs PostgreSQL (the compose files use postgres 18) and pict-rs for the full Lemmy stack; Docker for the getting-started flow.
- Dev defaults (SYSOP / 1234567890, DB password 12345678) are for local use only.
- No `.github/` workflows in this repo.

## Testing & QA
- There are currently no unit or integration tests in `crates/`; verify with `cargo build` and `cargo clippy --workspace`.
- End-to-end check: run `./scripts/start-getting-started.sh`, log in at `http://localhost:8536/api/v4/account/auth/login`, then call `POST http://localhost:8537/api/v4/pttbbs-lemmy/token` with the admin JWT (see `README.md`).
- Tests that touch the database require Postgres; never point them at real data.
