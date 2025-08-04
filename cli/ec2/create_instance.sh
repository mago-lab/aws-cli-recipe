#!/bin/bash
# encoding: utf-8
# Copyright (c) 2024- MAGO
# AUTHORS
# Sukbong Kwon (Galois)

# Create EC2 instance with the given AMI id

ami_id=ami-09a7535106fbd42d5    # t3.large Ubuntu, 22.04 LTS, amd64 jammy image build on 2024-03-01
instance_name=
without_eip=false

[ -f ./functions.sh ] && source ./functions.sh
. ./utils/parse_options.sh

help_message=(
"usage: $0 <vpc name>
    -h, --help                  # Show this message
    --ami-id                    # AMI id
    --instance-name             # Instance name
    --without-eip               # Skip Elastic IP allocation
    <vpc name>                  # VPC name
")

# VPC name is required
if [ $# -ne 1 ]; then
    printf "%s\n" "${help_message[@]}"
    exit 1;
fi
vpc_name=$1

# Check if you want to create an EC2 instance
echo -n "Do you want to create an EC2 instance '${vpc_name}'? (y/n) "
read answer
if [ $answer != "y" ]; then
    echo "Exiting..."
    exit 1
fi


# Generate IDs
vpc_id=$(get_vpc_id $vpc_name)
default_sg_id=$(get_default_sg_id $vpc_id)
elb_sg_id=$(get_sg_id "${vpc_name}-elb-sg")
public_subnet1_id=$(get_subnet_id "${vpc_name}-public-subnet1")
public_subnet2_id=$(get_subnet_id "${vpc_name}-public-subnet2")

# Set instance name
if [ -z $instance_name ]; then
    echo -n "Enter instance name: "
    read instance_name

    if [ -z $instance_name ]; then
        instance_name="${vpc_name}-ec2"
    fi
fi

padding_length=30
printf "============================================================\n"
printf "%-${padding_length}s %s\n" "VPC Name" ": ${vpc_name}"
printf "%-${padding_length}s %s\n" "VPC ID" ": ${vpc_id}"
printf "%-${padding_length}s %s\n" "Default SG" ": ${default_sg_id}"
printf "%-${padding_length}s %s\n" "Instance Name" ": ${instance_name}"
printf "============================================================\n"

# Create EC2 instance if it does not exist with instance name
instance_id=$(get_instance_id $instance_name)
if [ -z $instance_id ]; then
    echo "Creating EC2 instance..."
    # Audo-assing pulblic IP disabled
    # IMDSv2 set to `required`
    # Set the instance name with $instance_name
    aws --profile galois --region ap-northeast-2 \
        ec2 run-instances \
        --image-id ${ami_id} \
        --instance-type t3.large \
        --key-name mago-aws \
        --security-group-ids ${default_sg_id} ${elb_sg_id} \
        --subnet-id ${public_subnet1_id} \
        --no-associate-public-ip-address \
        --metadata-options HttpTokens=required \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${instance_name}}]"

    instance_id=$(get_instance_id $instance_name)
    printf "%-${padding_length}s %s\n" "Instance ID" ": ${instance_id}"
else
    printf "%-${padding_length}s %s\n" "Instance ID" ": ${instance_id}"
    echo "EC2 instance already exists."
fi

################################################
# Add inbound rule to the security group for SSH
inbound_rule=$(check_inbound_rule $default_sg_id 22)

if [ $? -ne 0 ]; then
    echo "Adding inbound rule to the security group for SSH..."
    aws --profile galois --region ap-northeast-2 \
        ec2 authorize-security-group-ingress \
        --group-id ${default_sg_id} \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0
    echo "Inbound rule added for SSH."
    inbound_rule=$(check_inbound_rule $default_sg_id 22)
    printf "%-${padding_length}s %s\n" "Inbound Rule for SSH" ": ${inbound_rule}"
else
    printf "%-${padding_length}s %s\n" "Inbound Rule for SSH" ": ${inbound_rule}"

    echo "Inbound rule for SSH already exists."
fi


###################################
# Allocate Elastic IP with name tag

if $without_eip; then
    echo "Skipping Elastic IP allocation."
    exit 1;
else
    instance_id=$(get_instance_id $instance_name)
    if [ -z $instance_id ]; then
        echo "Instance does not exist."
        exit 1
    fi

    eip_name="${instance_name}-eip"
    printf "%-${padding_length}s %s\n" "Elastic IP Name" ": ${eip_name}"

    # Find the Elastic IP with the given name tag
    eip_id=$(get_eip_id $eip_name)

    if [ -z $eip_id ]; then
        # Allocate Elastic IP with name tag
        echo "Allocating Elastic IP with name tag"
        eip=$(create_eip_with_name $eip_name)

        # Associate Elastic IP with the instance
        echo "Associating Elastic IP..."
        associate_eip $eip $instance_id

        printf "%-${padding_length}s %s\n" "Elastic IP" ": ${eip}"
    else
        eip=$(get_eip $eip_name)
        printf "%-${padding_length}s %s\n" "Elastic IP" ": ${eip}"
        echo "Elastic IP already exists."
    fi
fi