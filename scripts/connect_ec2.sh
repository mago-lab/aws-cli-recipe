#!/bin/bash

help_message=(
"usage: $0 <EC2>
    --help                      # Show this message"
)

if [ $# -ne 1 ]; then
    printf "%s\n" "${help_message[@]}"
    exit 1;
fi
ec2=$1

[ -f env.sh ] && source env.sh

if [[ $ec2 == "cv" ]]; then
	ec2_ip=$cassette_dev_ec2_ip
elif [[ $ec2 == "cs" ]]; then
    ec2_ip=$cassette_stg_ec2_ip
elif [[ $ec2 == "jm" ]]; then
	ec2_ip=$junctionmed_ec2_ip
else
    echo "Usage: $0 <EC2>"
	exit 1;
fi

ssh -i mago-aws.pem ubuntu@$ec2_ip