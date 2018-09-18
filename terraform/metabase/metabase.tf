variable "vpc_id" {}
variable "public_subnet_id" {}
variable "private_subnet_id" {}
variable "db_subnet_group_name" {}
variable "beanstalk_role_name" {}

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

resource "aws_iam_role" "instance_role" {
  name = "metabase_instance_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "container" {
  role = "${aws_iam_role.instance_role.name}"
  policy_arn = "arn:aws-us-gov:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "web_tier" {
  role = "${aws_iam_role.instance_role.name}"
  policy_arn = "arn:aws-us-gov:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "metabase_instance_profile"
  role = "${aws_iam_role.instance_role.name}"
}

resource "aws_security_group" "elb_security" {
  name = "metabase_elb_security"
  vpc_id = "${data.aws_vpc.host.id}"

  # HTTP access from the VPC
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
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

resource "aws_security_group" "metabase_security" {
  name = "metabase_application_security"
  vpc_id = "${data.aws_vpc.host.id}"

  # HTTP access from the VPC
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.elb_security.id}"
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

resource "aws_acm_certificate" "metabase_cert" {
  domain_name       = "data.clearmyrecord.org"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
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

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "SecurityGroups"
    value = "${aws_security_group.metabase_security.id}"
  }

  setting {
    namespace = "aws:elb:listener:80"
    name = "ListenerEnabled"
    value = "false"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name = "InstancePort"
    value = "80"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name = "ListenerProtocol"
    value = "HTTPS"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name = "SSLCertificateId"
    value = "${aws_acm_certificate.metabase_cert.arn}"
  }

  setting {
    namespace = "aws:elb:loadbalancer"
    name = "SecurityGroups"
    value = "${aws_security_group.elb_security.id}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "IamInstanceProfile"
    value = "${aws_iam_instance_profile.instance_profile.name}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "ServiceRole"
    value = "${var.beanstalk_role_name}"
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
    name = "MB_DB_TYPE"
    value = "postgres"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "MB_DB_NAME"
    value = "metabase"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "MB_DB_PORT"
    value = "5432"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "MB_DB_HOST"
    value = "${aws_db_instance.metabase_db.address}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "MB_DB_USER"
    value = "metabase"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "MB_DB_PASS"
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
