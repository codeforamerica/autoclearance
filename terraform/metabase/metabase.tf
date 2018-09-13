variable "vpc_id" {}
variable "subnet_1_id" {}
variable "subnet_2_id" {}
variable "db_subnet_group_name" {}

data "aws_vpc" "host" {
  id = "${var.vpc_id}"
}

data "aws_subnet" "subnet_1" {
  id = "${var.subnet_1_id}"
}

data "aws_subnet" "subnet_2" {
  id = "${var.subnet_2_id}"
}

resource "aws_elastic_beanstalk_application" "beanstalk_application" {
  name = "Metabase"
}

resource "aws_kms_key" "k" {
  description = "metabase"
}

resource "random_string" "rds_password" {
  length = 32
}

resource "aws_security_group" "metabase_security" {
  name = "application_security"
  vpc_id = "${data.aws_vpc.host.id}"

  # HTTP access from the VPC
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      //"${aws_vpc.default.cidr_block}"
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
  name = "rds_security"
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
  availability_zone = "${data.aws_subnet.subnet_1.availability_zone}"
  db_subnet_group_name = "${var.db_subnet_group_name}"
  engine = "postgres"
  instance_class = "db.m3.medium"
  kms_key_id = "${aws_kms_key.k.arn}"
  name = "metabase"
  username = "metabase"
  password = "${random_string.rds_password}"
  storage_encrypted = true
  storage_type = "gp2"
  vpc_security_group_ids = [
    "${aws_security_group.rds_security.id}"
  ]
}

resource "aws_elastic_beanstalk_environment" "environment" {
  name = "metabase"
  application = "${aws_elastic_beanstalk_application.beanstalk_application.name}"
  solution_stack_name = "Docker running on 64bit Amazon Linux/2.12.2"
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
    namespace = "aws:ec2:vpc"
    name = "VPCId"
    value = "${data.aws_vpc.host.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "Subnets"
    value = "${data.aws_subnet.subnet_1.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBSubnets"
    value = "${data.aws_subnet.subnet_1.id}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "RDS_HOST"
    value = "${aws_db_instance.db.address}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "RDS_USERNAME"
    value = "${var.rds_username}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "RDS_PASSWORD"
    value = "${var.rds_password}"
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
