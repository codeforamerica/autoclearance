#!/usr/bin/env bash

set -e

mkdir ~/.aws
touch ~/.aws/config
chmod 600 ~/.aws/config
echo "[profile autoclearance]" > ~/.aws/config
echo "aws_access_key_id=$AWS_ACCESS_KEY_ID" >> ~/.aws/config
echo "aws_secret_access_key=$AWS_SECRET_KEY" >> ~/.aws/config
