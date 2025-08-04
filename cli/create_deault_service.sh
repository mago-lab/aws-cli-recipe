#!/bin/bash
# encoding: utf-8
# Copyright (c) 2024- MAGO
# AUTHORS
# Sukbong Kwon (Galois)

# 서비스가 가능한 기본적인 환경을 구성하는 스크립트
# 구성 환경:
#   - VPC
#       - Create VPC
#       - Create Subnets (Public 2, Private 2)
#       - Security Group (app, db, elb, default)
#   - ELB
#       - Create elastic load balancer
#       - Listener (HTTP 80)
#   - EC2
#       - Create EC2
#       - Allocation Elastic IP
#       - Associate Elastic IP
#   - Target Group
#       - Create target group
#       - Register targets
#   - Route 53
#       - Create record set


[ -f ./functions.sh ] && source ./functions.sh
. ./utils/parse_options.sh

help_message=("
usage: $0 <vpc name>
    --help                      # Show this message
    <vpc name>                  # VPC name
")

# VPC name is required
if [ $# -ne 1 ]; then
    printf "%s\n" "${help_message[@]}"
    exit 1;
fi
vpc_name=$1

#########################################
# Create VPC
#########################################

vpc_id=$(get_vpc_id $vpc_name)
if [ -z $vpc_id ]; then
    echo "Creating VPC..."
    # cd vpc
    # ./create_vpc.sh $vpc_name
    # cd ..
else
    echo "VPC '${vpc_name}' already exists"
fi

#########################################
# Elastic Load Balancer
#########################################

elb_name="${vpc_name}-elb"
./elb/create_elb.sh --elb-name $elb_name $vpc_name

#########################################
# EC2
#########################################

instance_name="${vpc_name}-ec2"
./ec2/create_instance.sh --instance-name $instance_name $vpc_name

#########################################
# Target Group
#########################################

tg_name="${vpc_name}-tg"
elb_name="${vpc_name}-elb"
domain_name=magostar.com

./tg/create_tg.sh \
    --tg-name $tg_name \
    --instance-name $instance_name \
    --elb-name $elb_name \
    --domain-name $domain_name \
    $vpc_name

#########################################
# Create record set in Route 53
#########################################

elb_name="${vpc_name}-elb"
domain_name=magostar.com

./elb/create_record.sh \
    --domain-name $domain_name \
    --elb-name $elb_name \
    $vpc_name


printf "생성된 EC2에 서비스를 배포하고, Route 53에 등록된 도메인으로 접속하여 확인하세요.\n"