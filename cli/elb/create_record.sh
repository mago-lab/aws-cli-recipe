#!/bin/bash
# encoding: utf-8
# Copyright (c) 2024- MAGO
# AUTHORS
# Sukbong Kwon (Galois)

# Create record in Route 53 with the given domain name
# and Elastic Load Balancer (ELB) name

domain_name=
elb_name=

[ -f ./functions.sh ] && source ./functions.sh
. ./utils/parse_options.sh

help_message=("
usage: $0 <vpc name>
    --help                      # Show this message
    --domain-name               # Domain name
    --elb-name                  # ELB name
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

# Set domain name
if [ -z $domain_name ]; then
    echo -n "Enter domain name: "
    read domain_name

    if [ -z $domain_name ]; then
        domain_name="magostar.com"
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

padding_length=30
printf "============================================================\n"
printf "%-${padding_length}s %s\n" "VPC Name" ": ${vpc_name}"
printf "%-${padding_length}s %s\n" "VPC ID" ": ${vpc_id}"
printf "%-${padding_length}s %s\n" "Domain Name" ": ${domain_name}"
printf "%-${padding_length}s %s\n" "ELB Name" ": ${elb_name}"
printf "============================================================\n"

# Create record in Route 53 with the given domain name
# and Elastic Load Balancer (ELB) name

# Get the hosted zone ID for your domain
hosted_zone_id=$(aws route53 list-hosted-zones \
    --query "HostedZones[?Name=='$domain_name.'].Id" \
    --output text \
    | cut -d'/' -f3)

printf "%-${padding_length}s %s\n" "Hosted Zone ID" ": ${hosted_zone_id}"

# Create a record in Route 53 with the given domain name
elb_hosted_zone_id=$(aws --profile galois --region ap-northeast-2 \
    elbv2 describe-load-balancers \
    --names $elb_name \
    --query 'LoadBalancers[].CanonicalHostedZoneId' \
    --output text)

elb_dns_name=$(aws --profile galois --region ap-northeast-2 \
    elbv2 describe-load-balancers \
    --names $elb_name \
    --query 'LoadBalancers[].DNSName' \
    --output text)

printf "%-${padding_length}s %s\n" "ELB DNS Name" ": ${elb_dns_name}"
printf "%-${padding_length}s %s\n" "ELB Hosted Zone ID" ": ${elb_hosted_zone_id}"

record_name=$vpc_name
record_domain_name=$record_name.$domain_name
dualstack_elb_dns_name=dualstack.$elb_dns_name

aws --profile galois --region ap-northeast-2 \
    route53 change-resource-record-sets \
    --hosted-zone-id "$hosted_zone_id" \
    --change-batch '{
        "Changes": [
            {
                "Action": "CREATE",
                "ResourceRecordSet": {
                    "Name": "'"$record_domain_name"'",
                    "Type": "A",
                    "AliasTarget": {
                        "HostedZoneId": "'"$elb_hosted_zone_id"'",
                        "DNSName": "'"$dualstack_elb_dns_name"'",
                        "EvaluateTargetHealth": false
                    }
                }
            }
        ]
    }'
