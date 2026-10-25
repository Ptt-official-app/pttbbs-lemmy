#!/bin/bash
#
# 1. prepare docs/examples/var/mail
# 2. docker compose to ensure running the containers.
# 3. swagger to generate the doc and the docker containers for localhost:8080
# 4. go build and run pttbbs-backend.

echo -e "\x1b[1;32m[Info] 2. docker compose\x1b[m"
docker compose -f docker/docker-compose.dev.yaml up -d

echo -e "\x1b[1;32m[Info] 4. cargo run pttbbs-lemmy\x1b[m"

export LEMMY_CONFIG_LOCATION="config/config.dev.hjson"
cargo run --bin pttbbs-lemmy
