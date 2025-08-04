#!/bin/bash
# encoding: utf-8
# Copyright (c) 2024- MAGO
# AUTHORS
# Sukbong Kwon (Galois)

help_message=("
usage: $0 <vpc name>
    --help                      # Show this message
    <vpc name>                  # VPC name
")

if [ $# -ne 1 ]; then
    printf "%s\n" "${help_message[@]}"
    exit 1;
fi

vpc_name=$1


# Get VPC id with the given VPC name
vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${vpc_name}" --query 'Vpcs[].VpcId' --output text)

echo "VPC id: ${vpc_id}"

# Get subnet id with the given subnet name
aws ec2 describe-subnets --filters "Name=tag:Name,Values=YourSubnetName" --query 'Subnets[*].[SubnetId]' --output text
