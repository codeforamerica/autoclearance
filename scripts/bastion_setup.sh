#!/usr/bin/env bash
set -e

IP=$1
SSH_KEY=$2

scp  -i "${SSH_KEY}" scripts/adduser.sh ec2-user@${IP}:
ssh ec2-user@${IP} -i "${SSH_KEY}" -C "chmod a+x ./adduser.sh && sudo ./adduser.sh"

ssh ec2-user@${IP} -i "${SSH_KEY}" -C "sudo yum update -y && sudo yum install -y awslogs"
scp -i "${SSH_KEY}" scripts/bastion_awslogs.conf ec2-user@${IP}:awslogs.conf
scp -i "${SSH_KEY}" scripts/bastion_awscli.conf ec2-user@${IP}:awscli.conf
ssh ec2-user@${IP} -i "${SSH_KEY}" -C "sudo mv awslogs.conf /etc/awslogs/awslogs.conf && sudo mv awscli.conf /etc/awslogs/awscli.conf && sudo service awslogs restart"
