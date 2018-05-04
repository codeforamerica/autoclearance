terraform {
  backend "s3" {
    bucket = "terraform-autoclearance-prod"
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

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "application_vpc"
  }
}

# Create a public subnet for our bastion
resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.0.0.0/24"
  tags {
    Name = "public"
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

resource "aws_network_acl" "default" {
  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = [
    "${aws_subnet.public.id}"
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

  tags {
    Name = "public"
  }
}

# Create a private subnet for our EC2 instance
resource "aws_subnet" "private" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.0.2.0/24"

  tags {
    Name = "private"
  }
}

resource "aws_eip" "eip" {
  vpc = true
  depends_on = [
    "aws_internet_gateway.default"]
}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.eip.id}"
  subnet_id = "${aws_subnet.public.id}"

  depends_on = [
    "aws_internet_gateway.default"]

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

resource "aws_network_acl" "private" {
  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = [
    "${aws_subnet.private.id}"
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

  tags {
    Name = "private"
  }
}

resource "aws_s3_bucket" "rap_sheet_inputs" {
  bucket = "autoclearance-rap-sheet-inputs"

  tags {
    Name = "Rap sheet inputs"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket" "autoclearance_outputs" {
  bucket = "autoclearance-outputs"

  tags {
    Name = "Autoclearance Outputs"
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_iam_user" "application_user" {
  name = "application"
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
          "${aws_s3_bucket.rap_sheet_inputs.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_group" "staff" {
  name = "staff"
}

resource "aws_iam_group_policy_attachment" "s3_read_write_for_staff" {
  group = "${aws_iam_group.staff.name}"
  policy_arn = "${aws_iam_policy.s3_read_write.arn}"
}

resource "aws_iam_user_policy_attachment" "application_policy_attachment" {
  user = "${aws_iam_user.application_user.name}"
  policy_arn = "${aws_iam_policy.s3_read_write.arn}"
}

resource "aws_key_pair" "auth" {
  key_name = "${var.key_name}"
  public_key = "${var.public_key}"
}

resource "aws_security_group" "bastion_security" {
  name = "bastion_security"
  vpc_id = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
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
}
