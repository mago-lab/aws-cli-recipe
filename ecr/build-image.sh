#!/usr/bin/env bash

export IMAGE=saturn_me
export MEE_IMAGE=mee-server
export TARGET=latest

# build image
# docker build --no-cache -t ${IMAGE}:${TARGET} .

# login
export ECR=639283300290.dkr.ecr.ap-northeast-2.amazonaws.com
aws ecr get-login-password --region  ap-northeast-2 | docker login --username AWS --password-stdin ${ECR}

# build tag
docker tag ${IMAGE}:${TARGET} ${ECR}/${MEE_IMAGE}:${TARGET}

# remove dangling images
# docker rmi -f $(docker images -f "dangling=true" -q)

