terraform {
  backend "s3" {
    key = "terraform_state"
    region = "us-gov-west-1"
  }
}

# Specify the provider and access details
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

module "main" {
  source = "../main"

  aws_az1 = "${var.aws_az1}"
  aws_az2 = "${var.aws_az2}"

  rds_username = "${var.rds_username}"

  analysis_rds_username = "${var.analysis_rds_username}"

  environment = "${var.environment}"
  rails_secret_key_base = "${var.rails_secret_key_base}"

  key_name = "${var.key_name}"
  public_key = "${var.public_key}"
}

output "rds_password" {
  value = "${module.main.rds_password}"
}

output "analysis_database_url" {
  value = "${module.main.analysis_database_url}"
}
