variable "aws_region" {
  description = "AWS region to launch servers."
  default = "us-gov-west-1"
}

variable "aws_az1" {
  description = "AWS availability zone 1"
  default = "us-gov-west-1a"
}

variable "aws_az2" {
  description = "AWS availability zone 2"
  default = "us-gov-west-1b"
}

variable "aws_access_key" {}
variable "aws_secret_key" {}
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
