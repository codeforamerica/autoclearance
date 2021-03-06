variable "aws_az1" {
  description = "AWS availability zone 1"
  default = "us-gov-west-1a"
}

variable "aws_az2" {
  description = "AWS availability zone 2"
  default = "us-gov-west-1b"
}

variable "rds_username" {}

variable "environment" {
  description = "environment name to append to s3 bucket names (e.g. staging, or prod)"
}

variable "rails_secret_key_base" {
  description = "Secret key base for Rails. Generated by running \"rake secret\""
}
variable "key_name" {
  description = "Desired name of AWS key pair"
}
variable "public_key" {
  description = <<DESCRIPTION
Public key associated with AWS key pair. 
Can be generated from the .pem file

Ensure this keypair is added to your local SSH agent so provisioners can
connect.
DESCRIPTION
}