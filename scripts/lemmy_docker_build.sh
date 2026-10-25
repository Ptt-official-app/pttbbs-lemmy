#!/bin/bash

cd lemmy
docker compose -f docker/docker-compose.yml build lemmy
cd ..
