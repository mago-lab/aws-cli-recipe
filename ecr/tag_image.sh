#!/bin/bash

image_name=$1
tag=$2

# login
export ECR=905678327971.dkr.ecr.ap-northeast-2.amazonaws.com
aws ecr get-login-password --region  ap-northeast-2 | docker login --username AWS --password-stdin ${ECR}

# tag
MANIFEST=$(aws ecr batch-get-image --repository-name ${image_name} --image-ids imageTag=latest --output json | jq --raw-output --join-output '.images[0].imageManifest')
aws ecr put-image --repository-name ${image_name} --image-tag ${tag} --image-manifest "$MANIFEST"


