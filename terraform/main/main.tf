# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags {
    Name = "${var.environment}_vpc"
  }
}

# Create a public subnet for our bastion
resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "${var.aws_az1}"
  tags {
    Name = "public"
  }
}

# Create a second public subnet for our analysis db
resource "aws_subnet" "public_2" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.0.4.0/24"
  availability_zone = "${var.aws_az2}"
  tags {
    Name = "public 2"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route_table" "internet_access" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_route_table_association" "subnet_route_table" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.internet_access.id}"
}

resource "aws_route_table_association" "subnet_route_table_2" {
  subnet_id = "${aws_subnet.public_2.id}"
  route_table_id = "${aws_route_table.internet_access.id}"
}

resource "aws_network_acl" "public" {
  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = [
    "${aws_subnet.public.id}",
    "${aws_subnet.public_2.id}"
  ]
  egress {
    protocol = "-1"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }

  # SSH
  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 22
    to_port = 22
  }

  # Ephemeral ports for response packets
  ingress {
    protocol = "tcp"
    rule_no = 200
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }

  # HTTP
  ingress {
    protocol = "tcp"
    rule_no = 300
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }

  # HTTPS
  ingress {
    protocol = "tcp"
    rule_no = 400
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443
  }

  # Postgres
  ingress {
    protocol = "tcp"
    rule_no = 500
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 5432
    to_port = 5432
  }

  # Mailgun for Metabase
  ingress {
    protocol = "tcp"
    rule_no = 600
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 587
    to_port = 587
  }

  tags {
    Name = "public"
  }
}

# Create a private subnet for our EC2 instance
resource "aws_subnet" "private" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "${var.aws_az1}"
  tags {
    Name = "private"
  }
}

# Create a second private subnet for our db
resource "aws_subnet" "private_2" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "${var.aws_az2}"
  tags {
    Name = "private 2"
  }
}

resource "aws_eip" "eip" {
  vpc = true
  depends_on = [
    "aws_internet_gateway.default"
  ]
}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.eip.id}"
  subnet_id = "${aws_subnet.public.id}"

  depends_on = [
    "aws_internet_gateway.default"
  ]

  tags {
    Name = "NAT"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.gw.id}"
  }
}

resource "aws_route_table_association" "private_route_table" {
  subnet_id = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "private_route_table_2" {
  subnet_id = "${aws_subnet.private_2.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_network_acl" "private" {
  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = [
    "${aws_subnet.private.id}",
    "${aws_subnet.private_2.id}"
  ]
  egress {
    protocol = "-1"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }

  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 22
    to_port = 22
  }

  ingress {
    protocol = "tcp"
    rule_no = 200
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }

  ingress {
    protocol = "tcp"
    rule_no = 300
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }

  ingress {
    protocol = "tcp"
    rule_no = 400
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443
  }

  tags {
    Name = "private"
  }
}

resource "aws_kms_key" "k" {
  description = "autoclearance"
}

resource "aws_kms_alias" "k" {
  name = "alias/autoclearance"
  target_key_id = "${aws_kms_key.k.key_id}"
}

resource "aws_s3_bucket" "rap_sheet_inputs" {
  bucket = "autoclearance-rap-sheet-inputs-${var.environment}"

  tags {
    Name = "Rap sheet inputs"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.k.arn}"
        sse_algorithm = "aws:kms"
      }
    }
  }

  policy = <<POLICY
{
    "Version": "2008-10-17",
    "Id": "Policy5",
    "Statement": [
        {
            "Sid": "DenyUnSecureCommunications",
            "Effect": "Deny",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:*",
            "Resource": "arn:aws-us-gov:s3:::autoclearance-rap-sheet-inputs-${var.environment}/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_s3_bucket" "autoclearance_outputs" {
  bucket = "autoclearance-outputs-${var.environment}"

  tags {
    Name = "Autoclearance Outputs"
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.k.arn}"
        sse_algorithm = "aws:kms"
      }
    }
  }

  policy = <<POLICY
{
    "Version": "2008-10-17",
    "Id": "Policy-GENERATED-ID",
    "Statement": [
        {
            "Sid": "DenyUnSecureCommunications",
            "Effect": "Deny",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:*",
            "Resource": "arn:aws-us-gov:s3:::autoclearance-outputs-${var.environment}/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_iam_policy" "s3_read_write" {
  name = "s3_read_write"
  description = "Interact with S3 for application inputs and outputs"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:DeleteObject",
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetObjectAcl",
        "s3:GetBucketPolicy",
        "s3:GetBucketAcl"
      ],
      "Effect": "Allow",
      "Resource": [
          "${aws_s3_bucket.autoclearance_outputs.arn}",
          "${aws_s3_bucket.rap_sheet_inputs.arn}",
          "${aws_s3_bucket.autoclearance_outputs.arn}/*",
          "${aws_s3_bucket.rap_sheet_inputs.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "*"
    },
    {
      "Sid": "KMSPermissionsForAutoclearanceKey",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:ListKeyPolicies",
        "kms:ListRetirableGrants",
        "kms:GetKeyPolicy",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:ListResourceTags",
        "kms:ListGrants",
        "kms:GetParametersForImport",
        "kms:Encrypt",
        "kms:GetKeyRotationStatus",
        "kms:DescribeKey"
      ],
      "Resource": [
        "${aws_kms_key.k.arn}"
      ]
    },
    {
      "Sid": "GlobalKMSPermissions",
      "Effect": "Allow",
      "Action": [
        "kms:ListKeys",
        "kms:GenerateRandom",
        "kms:ListAliases",
        "kms:ReEncryptTo",
        "kms:GenerateDataKey",
        "kms:ReEncryptFrom"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_user_policy" "beanstalk_deploy" {
  name = "beanstalk_deploy"
  user = "${aws_iam_user.circleci.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:*",
        "cloudformation:*",
        "ec2:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "*"
      ]
    },
    {
      "Action": [
        "elasticbeanstalk:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws-us-gov:elasticbeanstalk:*::*/*"
      ]
    },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws-us-gov:s3:::elasticbeanstalk-*/*"
      ]
    },
    {
      "Action": [
        "iam:PassRole"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_iam_instance_profile.instance_profile.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "beanstalk_full" {
  user = "${aws_iam_user.circleci.name}"
  policy_arn = "arn:aws-us-gov:iam::aws:policy/AWSElasticBeanstalkFullAccess"
}

resource "aws_iam_user" "circleci" {
  name = "circleci"
}

resource "aws_iam_group" "staff" {
  name = "staff"
}

resource "aws_iam_group_policy_attachment" "s3_read_write_for_staff" {
  group = "${aws_iam_group.staff.name}"
  policy_arn = "${aws_iam_policy.s3_read_write.arn}"
}

resource "aws_key_pair" "auth" {
  key_name = "${var.key_name}"
  public_key = "${var.public_key}"
}

resource "aws_security_group" "bastion_security" {
  name = "bastion_security"
  vpc_id = "${aws_vpc.default.id}"

  # SSH access from CfA
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "69.12.169.82/32"
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

resource "aws_security_group" "application_security" {
  name = "application_security"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.bastion_security.id}"
    ]
  }

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
  name = "rds_security"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.application_security.id}"
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

resource "aws_security_group" "analysis_rds_security" {
  name = "analysis_rds_security"
  vpc_id = "${aws_vpc.default.id}"

  # psql access from CfA
  ingress {
    from_port = 5432
    to_port = 5432
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

resource "aws_instance" "bastion" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ec2_user"

    # The connection will use the local SSH agent for authentication.
  }

  tags {
    Name = "bastion"
  }

  instance_type = "t2.micro"
  ami = "ami-b2d056d3"
  # Amazon Linux AMI 2017.03.1 (HVM), SSD Volume Type
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = [
    "${aws_security_group.bastion_security.id}"
  ]
  subnet_id = "${aws_subnet.public.id}"
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.bastion_profile.name}"
}

resource "aws_iam_role" "bastion_role" {
  name = "bastion_role"

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

resource "aws_iam_role_policy_attachment" "bastion_logs_to_cloudwatch" {
  role = "${aws_iam_role.bastion_role.name}"
  policy_arn = "arn:aws-us-gov:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion_profile"
  role = "${aws_iam_role.bastion_role.name}"
}


resource "aws_elastic_beanstalk_application" "ng_beanstalk_application" {
  name = "Autoclearance"
}

resource "aws_iam_role" "instance_role" {
  name = "instance_role"

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

resource "aws_iam_role" "beanstalk_role" {
  name = "beanstalk_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "elasticbeanstalk"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eb_enhanced_health" {
  role = "${aws_iam_role.beanstalk_role.name}"
  policy_arn = "arn:aws-us-gov:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "eb_service" {
  role = "${aws_iam_role.beanstalk_role.name}"
  policy_arn = "arn:aws-us-gov:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

resource "aws_iam_role_policy_attachment" "worker_tier" {
  role = "${aws_iam_role.instance_role.name}"
  policy_arn = "arn:aws-us-gov:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "container" {
  role = "${aws_iam_role.instance_role.name}"
  policy_arn = "arn:aws-us-gov:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "web_tier" {
  role = "${aws_iam_role.instance_role.name}"
  policy_arn = "arn:aws-us-gov:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "logs_to_cloudwatch" {
  role = "${aws_iam_role.instance_role.name}"
  policy_arn = "arn:aws-us-gov:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role_policy_attachment" "s3_read_write" {
  role = "${aws_iam_role.instance_role.name}"
  policy_arn = "${aws_iam_policy.s3_read_write.arn}"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance_profile"
  role = "${aws_iam_role.instance_role.name}"
}

resource "aws_db_subnet_group" "default" {
  name = "main"
  subnet_ids = [
    "${aws_subnet.private.id}",
    "${aws_subnet.private_2.id}"
  ]

  tags {
    Name = "DB Subnet"
  }
}

resource "aws_db_subnet_group" "analysis_db" {
  name = "analysis_db"
  subnet_ids = [
    "${aws_subnet.public.id}",
    "${aws_subnet.public_2.id}"
  ]

  tags {
    Name = "Analysis DB Subnet"
  }
}

resource "random_string" "rds_password" {
  length = 30
  special = false
}

resource "random_string" "analysis_rds_password" {
  length = 30
  special = false
}

resource "aws_db_instance" "db" {
  allocated_storage = 10
  availability_zone = "${var.aws_az1}"
  db_subnet_group_name = "${aws_db_subnet_group.default.name}"
  engine = "postgres"
  instance_class = "db.m3.medium"
  kms_key_id = "${aws_kms_key.k.arn}"
  name = "autoclearance"
  username = "${var.rds_username}"
  password = "${random_string.rds_password.result}"
  storage_encrypted = true
  storage_type = "gp2"
  vpc_security_group_ids = [
    "${aws_security_group.rds_security.id}"
  ]
}

resource "aws_db_parameter_group" "force_ssl" {
  name   = "force-ssl"
  family = "postgres9.6"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_instance" "analysis_db" {
  allocated_storage = 10
  availability_zone = "${var.aws_az1}"
  db_subnet_group_name = "${aws_db_subnet_group.analysis_db.name}"
  engine = "postgres"
  identifier = "analysis"
  instance_class = "db.m3.medium"
  kms_key_id = "${aws_kms_key.k.arn}"
  name = "analysis"
  username = "${var.analysis_rds_username}"
  parameter_group_name = "${aws_db_parameter_group.force_ssl.name}"
  password = "${random_string.analysis_rds_password.result}"
  publicly_accessible = true
  storage_encrypted = true
  storage_type = "gp2"
  vpc_security_group_ids = [
    "${aws_security_group.analysis_rds_security.id}"
  ]
}

resource "aws_security_group" "elb_security" {
  name = "autoclearance_elb_security"
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_elastic_beanstalk_environment" "beanstalk_application_environment" {
  name = "autoclearance-${var.environment}"
  application = "${aws_elastic_beanstalk_application.ng_beanstalk_application.name}"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.8.4 running Ruby 2.5 (Puma)"
  tier = "WebServer"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = "t2.small"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "IamInstanceProfile"
    value = "${aws_iam_instance_profile.instance_profile.name}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "ImageId"

    # Amazon Linux AMI 2017.03.1 (HVM), SSD Volume Type
    value = "ami-b2d056d3"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "SecurityGroups"
    value = "${aws_security_group.application_security.id}"
  }

  setting {
    namespace = "aws:elb:loadbalancer"
    name = "SecurityGroups"
    value = "${aws_security_group.elb_security.id}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "ServiceRole"
    value = "${aws_iam_role.beanstalk_role.name}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "VPCId"
    value = "${aws_vpc.default.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "Subnets"
    value = "${aws_subnet.private.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBSubnets"
    value = "${aws_subnet.public.id}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name = "SystemType"
    value = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "SECRET_KEY_BASE"
    value = "${var.rails_secret_key_base}"
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
    value = "${random_string.rds_password.result}"
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

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name = "StreamLogs"
    value = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name = "DeleteOnTerminate"
    value = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name = "RetentionInDays"
    value = "3653"
  }
}

resource "aws_config_config_rule" "r" {
  name = "s3-bucket-ssl-requests-only"

  source {
    owner = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }

  depends_on = [
    "aws_config_configuration_recorder.default"
  ]
}

resource "aws_config_config_rule" "ssh" {
  name = "restricted-ssh"

  source {
    owner = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [
    "aws_config_configuration_recorder.default"
  ]
}

resource "aws_config_config_rule" "rds" {
  name = "rds-storage-encrypted"

  source {
    owner = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [
    "aws_config_configuration_recorder.default"
  ]
}

resource "aws_config_configuration_recorder_status" "status" {
  name = "${aws_config_configuration_recorder.default.name}"
  is_enabled = true
  depends_on = [
    "aws_config_delivery_channel.channel"
  ]
}

resource "aws_iam_role_policy_attachment" "a" {
  role = "${aws_iam_role.config.name}"
  policy_arn = "arn:aws-us-gov:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_s3_bucket" "config" {
  bucket = "awsconfig-example"
  force_destroy = true
  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Id": "Policy5",
  "Statement": [
    {
      "Sid": "DenyUnSecureCommunications",
      "Effect": "Deny",
      "Principal": {
        "AWS": "*"
      },
      "Action": "s3:*",
      "Resource": "arn:aws-us-gov:s3:::awsconfig-example/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_config_delivery_channel" "channel" {
  name = "example"
  s3_bucket_name = "${aws_s3_bucket.config.bucket}"
  depends_on = [
    "aws_config_configuration_recorder.default"
  ]
}

resource "aws_config_configuration_recorder" "default" {
  role_arn = "${aws_iam_role.config.arn}"
}

resource "aws_iam_role" "config" {
  name = "awsconfig"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "manage_config_bucket" {
  name = "manage_config_bucket"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.config.arn}",
        "${aws_s3_bucket.config.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "config-attach" {
  role = "${aws_iam_role.config.name}"
  policy_arn = "${aws_iam_policy.manage_config_bucket.arn}"
}

resource "aws_iam_policy" "mfa_policy" {
  name = "mfa"
  policy = "${file("../policies/mfa_policy.json")}"
}

resource "aws_iam_group_policy_attachment" "mfa_staff" {
  group = "${aws_iam_group.staff.name}"
  policy_arn = "${aws_iam_policy.mfa_policy.arn}"
}

resource "aws_iam_role" "cloudwatch_logs_role" {
  name = "cloudwatch_logs_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cloudwatch_s3_attach" {
  role = "${aws_iam_role.cloudwatch_logs_role.name}"
  policy_arn = "${aws_iam_policy.cloudwatch_s3_policy.arn}"
}

resource "aws_iam_policy" "cloudwatch_s3_policy" {
  name = "cloudwatch_s3"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailCreateAndUpdateS3LogStream",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.s3_logs.arn}:*",
        "${aws_cloudwatch_log_group.log_access_logs.arn}:*",
        "${aws_cloudwatch_log_group.management_logs.arn}:*"
      ]
    }
  ]
}
POLICY
}

resource "aws_cloudtrail" "s3_logs" {
  name = "s3-logs"
  s3_bucket_name = "${aws_s3_bucket.cloudtrail_s3_logs.id}"
  include_global_service_events = false
  enable_log_file_validation = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.s3_logs.arn}"
  cloud_watch_logs_role_arn = "${aws_iam_role.cloudwatch_logs_role.arn}"

  event_selector {
    read_write_type = "All"
    include_management_events = false

    data_resource {
      type = "AWS::S3::Object"
      values = [
        "${aws_s3_bucket.autoclearance_outputs.arn}/",
        "${aws_s3_bucket.rap_sheet_inputs.arn}/"
      ]
    }
  }
}

resource "aws_cloudtrail" "log_access_logs" {
  name = "log-access-logs"
  s3_bucket_name = "${aws_s3_bucket.cloudtrail_log_access_logs.id}"
  include_global_service_events = false
  enable_log_file_validation = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.log_access_logs.arn}"
  cloud_watch_logs_role_arn = "${aws_iam_role.cloudwatch_logs_role.arn}"

  event_selector {
    read_write_type = "All"
    include_management_events = false

    data_resource {
      type = "AWS::S3::Object"
      values = [
        "${aws_s3_bucket.cloudtrail_s3_logs.arn}/",
        "${aws_s3_bucket.cloudtrail_management_logs.arn}/"
      ]
    }
  }
}

resource "aws_cloudtrail" "management_logs" {
  name = "management-logs"
  s3_bucket_name = "${aws_s3_bucket.cloudtrail_management_logs.id}"
  include_global_service_events = true
  enable_log_file_validation = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.management_logs.arn}"
  cloud_watch_logs_role_arn = "${aws_iam_role.cloudwatch_logs_role.arn}"
}

resource "aws_s3_bucket" "cloudtrail_s3_logs" {
  bucket = "cloudtrail-s3-logs"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-s3-logs"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-s3-logs/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "DenyUnSecureCommunications",
            "Effect": "Deny",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:*",
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-s3-logs/*",
            "Condition": {
                "Bool": {
                   "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_s3_bucket" "cloudtrail_log_access_logs" {
  bucket = "cloudtrail-log-access-logs"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-log-access-logs"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-log-access-logs/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "DenyUnSecureCommunications",
            "Effect": "Deny",
            "Principal": {
              "AWS": "*"
            },
            "Action": "s3:*",
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-log-access-logs/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_s3_bucket" "cloudtrail_management_logs" {
  bucket = "cloudtrail-management-logs"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-management-logs"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-management-logs/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "DenyUnSecureCommunications",
            "Effect": "Deny",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:*",
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-management-logs/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_cloudwatch_log_group" "s3_logs" {
  name = "s3_logs"
}

resource "aws_cloudwatch_log_group" "log_access_logs" {
  name = "log_access_logs"
}

resource "aws_cloudwatch_log_group" "management_logs" {
  name = "management_logs"
}

output "rds_password" {
  value = "${random_string.rds_password.result}"
}

output "analysis_rds_password" {
  value = "${random_string.analysis_rds_password.result}"
}

output "aws_vpc_default_id" {
  value = "${aws_vpc.default.id}"
}

output "aws_subnet_public_id" {
  value = "${aws_subnet.public.id}"
}

output "aws_subnet_private_id" {
  value = "${aws_subnet.private.id}"
}

output "aws_db_subnet_group_default_name" {
  value = "${aws_db_subnet_group.default.name}"
}

output "aws_iam_role_beanstalk_role_name" {
  value = "${aws_iam_role.beanstalk_role.name}"
}
