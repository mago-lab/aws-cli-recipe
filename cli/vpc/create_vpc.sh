#!/bin/bash
# encoding: utf-8
# Copyright (c) 2024- MAGO
# AUTHORS
# Sukbong Kwon (Galois)

env_name=prod # dev, stage, prod

help_message=(
"usage: $0 <stack-name>
    --help                      # Show this message"
)

. ../../utils/parse_options.sh


if [ $# -ne 1 ]; then
    printf "%s\n" "${help_message[@]}"
    exit 1;
fi
stack_name=$1

print_info() {
    printf "%-25s %s\n" "$1" ": $2"
}


printf "============================================================\n"
print_info "VPC Stack Name" "${stack_name}"
print_info "Environment Name" "${env_name}"
print_info "AWS Profile" "galois"
print_info "AWS Region" "ap-northeast-2"
printf "============================================================\n"


# Apply the environment setting in 'config_template_vpc.yml'
sed "s/\${devenv}/$env_name/g" config_template_vpc.yml > config_vpc.yml
printf "The environment name '${env_name}' is applied to 'config_vpc.yml'.\n"

echo -n "Do you want to create '${stack_name}' VPC? (y/n): "
read answer

if [[ "$answer" == "y" || "$answer" == "yes" ]]; then
  echo "Creating ${stack_name} VPC..."
else
  echo "Cancelled."
  exit 1;
fi

if [ ! -f config_vpc.yml ]; then
    echo "The 'config_vpc.yml' file does not exist."
    exit 1;
fi

aws --profile galois --region ap-northeast-2 \
    cloudformation deploy \
    --stack-name ${stack_name} \
    --capabilities CAPABILITY_IAM \
    --template-file "./config_vpc.yml" \
    --parameter-overrides \
    AppIngressPort=80 \
    SingleNatGateway=true \
    VpcCIDR="10.10.0.0/16" \
    PublicSubnet1CIDR="10.10.1.0/24" \
    PublicSubnet2CIDR="10.10.2.0/24" \
    PrivateSubnet1CIDR="10.10.3.0/24" \
    PrivateSubnet2CIDR="10.10.4.0/24"
