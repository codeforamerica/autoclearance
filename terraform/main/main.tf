resource "aws_kms_key" "k" {
  description = "autoclearance"
}

resource "aws_kms_alias" "k" {
  name = "alias/autoclearance"
  target_key_id = "${aws_kms_key.k.key_id}"
}

resource "aws_s3_bucket" "rap_sheet_inputs" {
  bucket = "autoclearance-rap-sheet-inputs-${var.environment}"


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
  bucket = "awsconfig-${var.environment}"
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
      "Resource": "arn:aws-us-gov:s3:::awsconfig-${var.environment}/*",
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
  bucket = "cloudtrail-s3-logs-${var.environment}"
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
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-s3-logs-${var.environment}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-s3-logs-${var.environment}/*",
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
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-s3-logs-${var.environment}/*",
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
  bucket = "cloudtrail-log-access-logs-${var.environment}"
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
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-log-access-logs-${var.environment}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-log-access-logs-${var.environment}/*",
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
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-log-access-logs-${var.environment}/*",
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
  bucket = "cloudtrail-management-logs-${var.environment}"
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
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-management-logs-${var.environment}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-management-logs-${var.environment}/*",
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
            "Resource": "arn:aws-us-gov:s3:::cloudtrail-management-logs-${var.environment}/*",
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
