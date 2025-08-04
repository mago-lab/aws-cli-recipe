#!/bin/bash

# Pull docker image from AWS ECR

image_name=$1
tag=latest

. ./account_id.sh || exit 1;
. ./parse_options.sh || exit 1;


ECR=${account_id}.dkr.ecr.ap-northeast-2.amazonaws.com

aws ecr get-login-password --region  ap-northeast-2 | docker login --username AWS --password-stdin ${ECR}
docker pull ${ECR}/${image_name}:${tag}
docker tag ${ECR}/${image_name}:${tag} ${image_name}:${tag}
