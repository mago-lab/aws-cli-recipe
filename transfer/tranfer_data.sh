#!/bin/bash

ec2=cs

help_message=(
"Usage: $0 [options] <path>
    --help                      # Show this message
    --ec2                       # EC2 name
    <path>                      # File or folder path
")

[ -f env.sh ] && source env.sh
. ./utils/parse_options.sh


if [ $# -ne 1 ]; then
    printf "%s\n" "${help_message[@]}"
    exit 1;
fi
source_path=$1


if [[ $ec2 == "cv" ]]; then
    ec2_ip=$cassette_dev_ec2_ip
elif [[ $ec2 == "cs" ]]; then
    ec2_ip=$cassette_stg_ec2_ip
elif [[ $ec2 == "jm" ]]; then
    ec2_ip=$junctionmed_ec2_ip
else
    echo "Usage: $0 <EC2>"
fi

echo "===================="
echo "Target EC2: $ec2"
echo "EC2 IP: $ec2_ip"
echo "Source path: $source_path"
echo "===================="

echo "Transfering $1 to $ec2_ip..."
scp -i mago-aws.pem -r $1 ubuntu@$ec2_ip:
echo "--- Done ---"
