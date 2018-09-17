variable "vpc_id" {}
variable "public_subnet_id" {}
variable "private_subnet_id" {}
variable "db_subnet_group_name" {}
variable "role_name" {}
variable "profile_name" {}

data "aws_vpc" "host" {
  id = "${var.vpc_id}"
}

data "aws_subnet" "public_subnet" {
  id = "${var.public_subnet_id}"
}

data "aws_subnet" "private_subnet" {
  id = "${var.private_subnet_id}"
}

resource "aws_elastic_beanstalk_application" "beanstalk_application" {
  name = "Metabase"
}

resource "aws_kms_key" "k" {
  description = "metabase"
}

resource "random_string" "rds_password" {
  length = 32
  special = false
}

resource "aws_security_group" "metabase_security" {
  name = "metabase_application_security"
  vpc_id = "${data.aws_vpc.host.id}"

  # HTTP access from the VPC
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "${data.aws_vpc.host.cidr_block}"
      // THE ELB SECURITY GROUP FOR METABASE
    ]
  }

  # Elastic Beanstalk clock sync
  egress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_security_group" "rds_security" {
  name = "metabase_rds_security"
  vpc_id = "${data.aws_vpc.host.id}"

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.metabase_security.id}"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_db_instance" "metabase_db" {
  allocated_storage = 10
  availability_zone = "${data.aws_subnet.public_subnet.availability_zone}"
  db_subnet_group_name = "${var.db_subnet_group_name}"
  engine = "postgres"
  instance_class = "db.m3.medium"
  kms_key_id = "${aws_kms_key.k.arn}"
  name = "metabase"
  username = "metabase"
  password = "${random_string.rds_password.result}"
  storage_encrypted = true
  storage_type = "gp2"
  vpc_security_group_ids = [
    "${aws_security_group.rds_security.id}"
  ]
}

resource "aws_elastic_beanstalk_environment" "environment" {
  name = "metabase"
  application = "${aws_elastic_beanstalk_application.beanstalk_application.name}"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.12.2 running Docker 18.03.1-ce"
  tier = "WebServer"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = "t2.micro"
  }

//  setting {
//    namespace = "aws:autoscaling:launchconfiguration"
//    name = "SecurityGroups"
//    value = "${aws_security_group.application_security.id}"
//  }
//
//  setting {
//    namespace = "aws:elasticbeanstalk:environment"
//    name = "ServiceRole"
//    value = "${aws_iam_role.beanstalk_role.name}"
//  }
//

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "IamInstanceProfile"
    value = "${var.profile_name}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "ServiceRole"
    value = "${var.role_name}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "VPCId"
    value = "${data.aws_vpc.host.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "Subnets"
    value = "${data.aws_subnet.private_subnet.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBSubnets"
    value = "${data.aws_subnet.public_subnet.id}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "RDS_HOST"
    value = "${aws_db_instance.metabase_db.address}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "RDS_USERNAME"
    value = "metabase"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "RDS_PASSWORD"
    value = "${random_string.rds_password.result}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name = "SystemType"
    value = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name = "ManagedActionsEnabled"
    value = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name = "PreferredStartTime"
    value = "Tue:16:00"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name = "UpdateLevel"
    value = "minor"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name = "InstanceRefreshEnabled"
    value = "true"
  }
}
