variable "aws_region" {
  description = "AWS region to launch servers."
  default = "us-gov-west-1"
}

variable "aws_access_key" {
  default = "AKIAKWJDXS2RPM6CWPCA"
}

variable "aws_secret_key" {
  default = "S1d1HiMqpRob9pHf8+CL+GcqXjg6cNyZAobWcKa6"
}

//##########
//
//variable "public_key_path" {
//  description = <<DESCRIPTION
//Path to the SSH public key to be used for authentication.
//Ensure this keypair is added to your local SSH agent so provisioners can
//connect.
//Example: ~/.ssh/terraform.pub
//DESCRIPTION
//}
//
//variable "key_name" {
//  description = "Desired name of AWS key pair"
//}
//
//
//
//# Ubuntu Precise 12.04 LTS (x64)
//variable "aws_amis" {
//  default = {
//    eu-west-1 = "ami-674cbc1e"
//    us-east-1 = "ami-1d4e7a66"
//    us-west-1 = "ami-969ab1f6"
//    us-west-2 = "ami-8803e0f0"
//  }
//}
