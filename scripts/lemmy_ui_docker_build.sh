#!/bin/bash

cd lemmy-ui
docker build -t docker-lemmy-ui:latest .
cd ..
