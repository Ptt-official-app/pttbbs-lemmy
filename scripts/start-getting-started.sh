#!/bin/bash
#
# 1. docker compose to ensure running the containers (lemmy, postgres, pictrs, lemmy-ui).
# 2. cargo run pttbbs-lemmy.

echo -e "\x1b[1;32m[Info] 1. docker compose\x1b[m"
docker compose -f docker/docker-compose.dev.yaml up -d

echo -e "\x1b[1;32m[Info] 2. cargo run pttbbs-lemmy\x1b[m"

export LEMMY_CONFIG_LOCATION="config/config.dev.hjson"
cargo run --bin pttbbs-lemmy
