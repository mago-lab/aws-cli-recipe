#!/bin/bash
# encoding: utf-8
# Copyright (c) 2024- MAGO
# AUTHORS
# Sukbong Kwon (Galois)


###################################
# Certificate Manager
###################################

# Get certificate arn with the given with the domain name
get_certificate_arn() {
    domain_name=$1
    certificate_arn=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$domain_name'].CertificateArn" --output text)
    echo $certificate_arn
}

###################################
# Virtual Private Cloud (VPC)
###################################

# Get VPC id with the given VPC name
get_vpc_id() {
    vpc_name=$1
    vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${vpc_name}" --query 'Vpcs[].VpcId' --output text 2>&1)
    if [ $? -ne 0 ]; then
        echo ""
    else
        echo "$vpc_id"
    fi
}

# Get subnet id with the given subnet name
get_subnet_id() {
    subnet_name=$1
    subnet_id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${subnet_name}" --query 'Subnets[*].[SubnetId]' --output text)
    echo $subnet_id
}

###################################
# Security Group
###################################

# Get security group id with the given security group name
get_sg_id() {
    sg_name=$1
    sg_id=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=${sg_name}" --query 'SecurityGroups[*].[GroupId]' --output text)
    echo $sg_id
}

# Get default security group id with the given VPC id
get_default_sg_id() {
    vpc_id=$1
    default_sg_id=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${vpc_id}" "Name=group-name,Values=default" --query 'SecurityGroups[*].[GroupId]' --output text)
    echo $default_sg_id
}

###################################
# Elastic Load Balancer
###################################

# Check if the given ELB name exists
get_elb_arn() {
    elb_name=$1
    elb_arn=$(aws elbv2 describe-load-balancers --names "$elb_name" --query 'LoadBalancers[].LoadBalancerArn' --output text 2>&1)
    if [ $? -ne 0 ]; then
        echo ""
    else
        echo "$elb_arn"
    fi
}


# Get listener with the given ELB arn
get_listener_arn() {
    elb_arn=$1
    listener_arn=$(aws elbv2 describe-listeners --load-balancer-arn "$elb_arn" --query 'Listeners[].ListenerArn' --output text)
    echo $listener_arn
}

# Get listener protocol with port
get_listener_protocol_80() {
    elb_arn=$1
    listener_protocol=$(aws elbv2 describe-listeners --load-balancer-arn "$elb_arn" --query 'Listeners[?Port==`80`].Protocol' --output text)
    echo $listener_protocol
}

# Get listener protocol with port
get_listener_protocol_443() {
    elb_arn=$1
    listener_protocol=$(aws elbv2 describe-listeners --load-balancer-arn "$elb_arn" --query 'Listeners[?Port==`443`].Protocol' --output text)
    echo $listener_protocol
}

# Check if the instance exists with the given instance name
get_instance_id() {
    instance_name=$1
    instance_id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${instance_name}" --query 'Reservations[].Instances[].InstanceId' --output text)
    echo $instance_id
}


# Check inbound rule with the given security group id, port
check_inbound_rule() {
    sg_id=$1
    port=$2
    inbound_rule=$(aws ec2 describe-security-groups --group-ids $sg_id --query 'SecurityGroups[].IpPermissions[?ToPort==`'$port'`]' --output text)
    echo $inbound_rule
}

###################################
# Elastic IP
###################################
# Find eip id with the given eip name
get_eip_id() {
    eip_name=$1
    eip_id=$(aws ec2 describe-addresses --filters "Name=tag:Name,Values=${eip_name}" --query 'Addresses[].AllocationId' --output text)
    echo $eip_id
}

# Get eip with the given eip name
get_eip() {
    eip_name=$1
    eip=$(aws ec2 describe-addresses --filters "Name=tag:Name,Values=${eip_name}" --query 'Addresses[].PublicIp' --output text)
    echo $eip
}

# Allocate Elastic IP with name tag
create_eip_with_name() {
    eip_name=$1
    eip=$(aws --profile galois --region ap-northeast-2 \
        ec2 allocate-address --domain vpc --query 'PublicIp' --output text)
    eip_allocation_id=$(aws --profile galois --region ap-northeast-2 \
        ec2 describe-addresses --public-ips $eip --query 'Addresses[].AllocationId' --output text)
    aws --profile galois --region ap-northeast-2 \
        ec2 create-tags --resources $eip_allocation_id --tags Key=Name,Value=$eip_name
    echo $eip
}

# Associate Elastic IP with the instance
associate_eip() {
    eip=$1
    instance_id=$2
    eip_allocation_id=$(aws --profile galois --region ap-northeast-2 \
        ec2 describe-addresses --public-ips $eip --query 'Addresses[].AllocationId' --output text)
    aws --profile galois --region ap-northeast-2 \
        ec2 associate-address --instance-id $instance_id --public-ip $eip
}


###################################
# Target Group
###################################

# Get target group arn with the given target group name
get_tg_arn() {
    tg_name=$1
    tg_arn=$(aws elbv2 describe-target-groups --names "$tg_name" --query 'TargetGroups[].TargetGroupArn' --output text 2>&1)
    if [ $? -ne 0 ]; then
        echo ""
    else
        echo "$tg_arn"
    fi
}