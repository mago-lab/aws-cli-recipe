#!/bin/bash
# encoding: utf-8
# Copyright (c) 2024- MAGO
# AUTHORS
# Sukbong Kwon (Galois)

tg_name=            # Target Group name
instance_name=      # Instance name
elb_name=           # ELB name
domain_name=magostar.com

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

# Check if the VPC exists
vpc_id=$(get_vpc_id $vpc_name)
if [ -z $vpc_id ]; then
    echo "VPC '${vpc_name}' does not exist"
    exit 1
fi

# Set target group name
if [ -z $tg_name ]; then
    echo -n "Enter target group name: "
    read tg_name

    if [ -z $tg_name ]; then
        tg_name="${vpc_name}-tg"
    fi
fi

# Set instance name
if [ -z $instance_name ]; then
    echo -n "Enter instance name: "
    read instance_name

    if [ -z $instance_name ]; then
        instance_name="${vpc_name}-ec2"
    fi
fi

# Set ELB name
if [ -z $elb_name ]; then
    echo -n "Enter ELB name: "
    read elb_name

    if [ -z $elb_name ]; then
        elb_name="${vpc_name}-elb"
    fi
fi

# Check if the instance exists
instance_id=$(get_instance_id $instance_name)
if [ -z $instance_id ]; then
    echo "Instance '${instance_name}' does not exist"
    exit 1
else
    echo "Instance ID: ${instance_id}"
fi

# Generate IDs
default_sg_id=$(get_default_sg_id $vpc_id)      # Default security group id
elb_arn=$(get_elb_arn $elb_name)                # ELB arn

padding_length=30
printf "============================================================\n"
printf "%-${padding_length}s %s\n" "VPC Name" ": ${vpc_name}"
printf "%-${padding_length}s %s\n" "VPC ID" ": ${vpc_id}"
printf "%-${padding_length}s %s\n" "Default SG" ": ${default_sg_id}"
printf "%-${padding_length}s %s\n" "Target Group Name" ": ${tg_name}"
printf "%-${padding_length}s %s\n" "Instance Name" ": ${instance_name}"
printf "%-${padding_length}s %s\n" "Instance ID" ": ${instance_id}"
printf "%-${padding_length}s %s\n" "ELB Name" ": ${elb_name}"
printf "%-${padding_length}s %s\n" "ELB ARN" ": ${elb_arn}"
printf "============================================================\n"

# Get target group arn with the given target group name
tg_arn=$(get_tg_arn $tg_name)

# Create target group if it does not exist with the given target group name
if [ -z $tg_arn ]; then
    echo "Creating target group..."
    tg_arn=$(aws --profile galois --region ap-northeast-2 \
        elbv2 create-target-group \
        --name $tg_name \
        --protocol HTTP \
        --port 80 \
        --vpc-id $vpc_id \
        --target-type instance \
        --query 'TargetGroups[].TargetGroupArn' \
        --output text)
    echo "Target Group created: ${tg_arn}"

    echo "Registering the EC2 instance with the target group..."
    aws --profile galois --region ap-northeast-2 \
        elbv2 register-targets \
        --target-group-arn $tg_arn \
        --targets Id=$instance_id
    echo "EC2 instance registered with the target group."
    printf "%-${padding_length}s %s\n" "Target Group ARN" ": ${tg_arn}"
else
    printf "%-${padding_length}s %s\n" "Target Group ARN" ": ${tg_arn}"
    echo "Target group already exists."
fi

# Create listener with the target group to the load balancer
if [ -z $elb_arn ]; then
    echo "ELB does not exist."
    exit 1
else
    # Check certificate with the given domain name
    certificate_arn=$(get_certificate_arn $domain_name)
    if [ -z $certificate_arn ]; then
        echo "Certificate does not exist."
        exit 1
    fi
    printf "%-${padding_length}s %s\n" "Certificate ARN" ": ${certificate_arn}"

    protocol=$(get_listener_protocol_443 $elb_arn)
    if [ ! -z $protocol ]; then
        echo "Listener already exists."
        exit 1
    fi

    echo "Creating listener..."
    aws --profile galois --region ap-northeast-2 \
        elbv2 create-listener \
        --load-balancer-arn $elb_arn \
        --protocol HTTPS \
        --port 443 \
        --ssl-policy ELBSecurityPolicy-TLS13-1-2-2021-06 \
        --certificates CertificateArn=$certificate_arn \
        --default-actions Type=forward,TargetGroupArn=$tg_arn
    echo "Listener created."
fi
