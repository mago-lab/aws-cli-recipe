#!/bin/bash
# encoding: utf-8
# Copyright (c) 2024- MAGO
# AUTHORS
# Sukbong Kwon (Galois)

help_message=(
"usage: $0 <image-id>
    --help                      # Show this message"
)

[ -f config/cassette.sh ] && source config/cassette.sh

image_id=ami-0382ac14e5f06eb95
eip_name="cassette-stg-ec2"


# Get the instance id with the given image id
instance_id=$(aws ec2 describe-instances --filters "Name=image-id,Values=${image_id}" --query 'Reservations[].Instances[].InstanceId' --output text)

##########################################
# Create EC2 instance if it does not exist
if [ -z $instance_id ]; then
    echo "Creating EC2 instance..."
    # Audo-assing pulblic IP disabled
    # IMDSv2 set to `required`
    aws --profile galois --region ap-northeast-2 \
        ec2 run-instances \
        --image-id ${image_id} \
        --instance-type c5a.large \
        --key-name mago-aws \
        --security-group-ids ${cassette_default_sg_id} \
        --subnet-id ${cassette_stg_public_subnet1_id} \
        --no-associate-public-ip-address \
        --metadata-options HttpTokens=required
else
    echo "EC2 instance already exists."
fi

###################################
# Allocate Elastic IP with name tag
if [ -z $instance_id ]; then
    echo "Allocating Elastic IP... with name tag"
    eip=$(aws --profile galois --region ap-northeast-2 \
        ec2 allocate-address --domain vpc --query 'PublicIp' --output text)
    echo "Elastic IP: ${eip}"

    # Get allocation id
    eip_allocation_id=$(aws --profile galois --region ap-northeast-2 \
        ec2 describe-addresses --public-ips $eip --query 'Addresses[].AllocationId' --output text)
    echo "Elastic IP allocation id: ${eip_allocation_id}"

    # Tag the Elastic IP
    aws --profile galois --region ap-northeast-2 \
        ec2 create-tags --resources $eip_allocation_id --tags Key=Name,Value=${eip_name}
    echo "Elastic IP tagged with name: ${eip_name}"

    # Associate Elastic IP with the instance
    echo "Associating Elastic IP..."
    aws --profile galois --region ap-northeast-2 \
        ec2 associate-address --instance-id $instance_id --public-ip $eip
else
    echo "Elastic IP already exists."
fi

########################################
# Add inbound rule to the security group
if [ -z $instance_id ]; then
    echo "Adding inbound rule to the security group with security group id: ${cassette_default_sg_id}"
    aws --profile galois --region ap-northeast-2 \
        ec2 authorize-security-group-ingress \
        --group-id ${cassette_default_sg_id} \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0
    echo "Inbound rule added."
else
    echo "Inbound rule already exists."
fi


# Create tartget group and register the EC2 instance with the target group
if [ -z $instance_id ]; then
    echo "Creating target group..."
    target_group_arn=$(aws --profile galois --region ap-northeast-2 \
        elbv2 create-target-group \
        --name cassette-stg-tg \
        --protocol HTTP \
        --port 80 \
        --vpc-id ${cassette_stg_vpc_id} \
        --target-type instance \
        --query 'TargetGroups[].TargetGroupArn' \
        --output text)
    echo "Target group created: ${target_group_arn}"

    echo "Registering the EC2 instance with the target group..."
    aws --profile galois --region ap-northeast-2 \
        elbv2 register-targets \
        --target-group-arn $target_group_arn \
        --targets Id=$instance_id
    echo "EC2 instance registered with the target group."
else
    echo "Target group and EC2 instance already exist."
fi

# Create load balancer and listener with certificate
# if [ -z $instance_id ]; then
    echo "Creating load balancer..."
    lb_arn=$(aws --profile galois --region ap-northeast-2 \
        elbv2 create-load-balancer \
        --name cassette-stg-lb \
        --subnets ${cassette_stg_public_subnet1_id} ${cassette_stg_public_subnet2_id} \
        --security-groups ${cassette_stg_elb_sg_id} \
        --query 'LoadBalancers[].LoadBalancerArn' \
        --output text)
    echo "Load balancer created: ${lb_arn}"

    echo "Get target group ARN with the name: cassette-stg-tg"
    target_group_arn=$(aws --profile galois --region ap-northeast-2 \
        elbv2 describe-target-groups \
        --names cassette-stg-tg \
        --query 'TargetGroups[].TargetGroupArn' \
        --output text)

    echo "Creating listener... HTTP:80 to redirect URL to HTTPS:443"
    echo "Creating listener... HTTPS:443 with certificate to target group"
    aws --profile galois --region ap-northeast-2 \
        elbv2 create-listener \
        --load-balancer-arn $lb_arn \
        --protocol HTTP \
        --port 80 \
        --default-actions "Type=redirect,RedirectConfig={Protocol=HTTPS,Port=443,Host=\"#{host}\",Path=\"/#{path}\",Query=\"#{query}\",StatusCode=HTTP_301}"
    aws --profile galois --region ap-northeast-2 \
        elbv2 create-listener \
        --load-balancer-arn $lb_arn \
        --protocol HTTPS \
        --port 443 \
        --ssl-policy ELBSecurityPolicy-2016-08 \
        --certificates CertificateArn=${certificate_arn} \
        --default-actions "Type=forward,TargetGroupArn=${target_group_arn}"
    echo "Listener created."
# else
#     echo "Load balancer and listener already exist."
# fi
