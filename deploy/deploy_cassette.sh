#!/bin/bash
# encoding: utf-8
# Copyright (c) 2022-2024 SATURN
# AUTHORS
# Sukbong Kwon (Galois)

# Before running this script, you need to `git pull`
# the latest version of the code from the repository,
# and checkout release branch for deployment.


# This script is for deploying the `backend-cassette`
cd backend-cassette
sed -i 's:8010:80:g' docker-compose.yml
docker-compose build
docker-compose up -d