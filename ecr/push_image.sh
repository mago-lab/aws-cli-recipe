#!/bin/bash

# Push docker image to AWS ECR

image_name=$1
tag=latest

. ./account_id.sh || exit 1;
. ./parse_options.sh || exit 1;

# login
ECR=${account_id}.dkr.ecr.ap-northeast-2.amazonaws.com
aws ecr get-login-password --region  ap-northeast-2 | docker login --username AWS --password-stdin ${ECR}

# create ecr repository
aws ecr create-repository --repository-name ${image_name}

# tag
docker tag ${image_name}:${tag} ${ECR}/${image_name}:${tag}
docker push ${ECR}/${image_name}:${tag}