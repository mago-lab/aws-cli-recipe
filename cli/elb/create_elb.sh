#!/bin/bash
# encoding: utf-8
# Copyright (c) 2024- MAGO
# AUTHORS
# Sukbong Kwon (Galois)

# Create ELB(Elastic Load Balancer) and attach it to the existing VPC

elb_name=

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

# Generate names
public_subnet1="${vpc_name}-public-subnet1"
public_subnet2="${vpc_name}-public-subnet2"
# private_subnet1="${vpc_name}-private-subnet1"
# private_subnet2="${vpc_name}-private-subnet2"
elb_sg="${vpc_name}-elb-sg"

# Generate IDs
vpc_id=$(get_vpc_id $vpc_name)
public_subnet1_id=$(get_subnet_id $public_subnet1)
public_subnet2_id=$(get_subnet_id $public_subnet2)
# private_subnet1_id=$(get_subnet_id $private_subnet1)
# private_subnet2_id=$(get_subnet_id $private_subnet2)
elb_sg_id=$(get_sg_id $elb_sg)
default_sg_id=$(get_default_sg_id $vpc_id)

padding_length=30
printf "============================================================\n"
printf "%-${padding_length}s %s\n" "VPC Name" ": ${vpc_name}"
printf "%-${padding_length}s %s\n" "VPC ID" ": ${vpc_id}"
printf "%-${padding_length}s %s\n" "${public_subnet1}" ": ${public_subnet1_id}"
printf "%-${padding_length}s %s\n" "${public_subnet2}" ": ${public_subnet2_id}"
printf "%-${padding_length}s %s\n" "${elb_sg}" ": ${elb_sg_id}"
printf "%-${padding_length}s %s\n" "Default SG" ": ${default_sg_id}"
printf "============================================================\n"

# Check ELB name
if [ -z $elb_name ]; then
    echo -n "Enter ELB name: "
    read elb_name

    if [ -z $elb_name ]; then
        elb_name="${vpc_name}-elb"
    fi
fi
printf "ELB Name: ${elb_name}\n"

#==============================================
# Create ELB
# Load balancer type: application
# Scheme: internet-facing
# Security groups: elb_sg, default_sg
# Subnets: public_subnet1, public_subnet2
#==============================================
elb_arn=$(get_elb_arn "$elb_name")
printf "%-${padding_length}s %s\n" "ELB arn" ": ${elb_arn}"
if [ -z $elb_arn ]; then
    echo "Creating ELB..."
    aws --profile galois --region ap-northeast-2 \
        elbv2 create-load-balancer \
        --type application \
        --name ${elb_name} \
        --subnets ${public_subnet1_id} ${public_subnet2_id} \
        --security-groups ${elb_sg_id} ${default_sg_id} \
        --scheme internet-facing
else
    echo "ELB already exists."
fi

protocol=$(get_listener_protocol_80 $elb_arn)

if [ -z $protocol ]; then
    printf "%-${padding_length}s %s\n" "Listener Protocol" ": HTTP:80"
    echo "Creating listener HTTP:80 to redirect URL to HTTPS:443"
    aws --profile galois --region ap-northeast-2 \
        elbv2 create-listener \
        --load-balancer-arn $elb_arn \
        --protocol HTTP \
        --port 80 \
        --default-actions "Type=redirect,RedirectConfig={Protocol=HTTPS,Port=443,Host=\"#{host}\",Path=\"/#{path}\",Query=\"#{query}\",StatusCode=HTTP_301}"
else
    printf "%-${padding_length}s %s\n" "Listener Protocol" ": ${protocol}:80"
    echo "Listener already exists."
fi
