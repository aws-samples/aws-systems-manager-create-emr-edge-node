# Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

provider "aws" {
  region     = "${var.region}"
}

data "template_file" "ssm_doc_edge_node" {
  template = "${file("${path.module}/ssm_doc_edge_node.tpl")}"

  vars = {
    SSMRoleArn = "${aws_iam_role.ssm_automation_role.arn}"
    InstanceProfileArn = "${aws_iam_instance_profile.edge_node_profile.arn}"
    PlaybookUrl = "s3://${var.bucket}/init.yaml"
    Environment = "${var.environment}"
    Project = "${var.ProjectTag}"
    region = "${var.region}"
  }
}

resource "aws_ssm_document" "create_edge_node" {
  name          = "create_edge_node"
  document_type = "Automation"
  document_format = "YAML"
  tags = {
    Name = "create_edge_node"
    Project = "${var.ProjectTag}"
    Environment = "${var.environment}"
  }

  content = "${data.template_file.ssm_doc_edge_node.rendered}"
}

resource "aws_iam_role" "ssm_automation_role" {
  name_prefix = "ssm_automation_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ssm.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
  tags = {
    Name = "ssm_automation_role"
    Project = "${var.ProjectTag}"
    Environment = "${var.environment}"
  }
}

resource "aws_iam_role_policy" "ssm_ec2_access" {
  name_prefix = "ssm_ec2_access"
  role = "${aws_iam_role.ssm_automation_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "iam:GetRole"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "iam:GetPolicyVersion"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "iam:GetPolicy"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "iam:CreateServiceLinkedRole"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "iam:PassRole"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ssm:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_iam_instance_profile" "edge_node_profile" {
  name_prefix = "edge_node_profile"
  role = "${aws_iam_role.edge_ec2_role.name}"
}
resource "aws_iam_role" "edge_ec2_role" {
  name_prefix = "edge_ec2_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
  tags = {
    Name = "edge_ec2_role"
    Project = "${var.ProjectTag}"
    Environment = "${var.environment}"
  }
}
resource "aws_iam_role_policy_attachment" "edge_ec2_role_ssm_policy" {
  role       = "${aws_iam_role.edge_ec2_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}
resource "aws_iam_role_policy_attachment" "edge_ec2_role_s3_policy" {
  role       = "${aws_iam_role.edge_ec2_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

data "template_file" "ansible_rstudio" {
  template = "${file("${path.module}/ansible_rstudio.tpl")}"
}
resource "aws_s3_bucket_object" "ansible_rstudio" {
  key                    = "init.yaml"
  bucket                 = "${var.bucket}"
  content = "${data.template_file.ansible_rstudio.rendered}"
}

resource "aws_iam_role" "cw_automation_role" {
  name_prefix = "cw_automation_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "cloudwatch.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
  tags = {
    Name = "cw_automation_role"
    Project = "${var.ProjectTag}"
    Environment = "${var.environment}"
  }
}

resource "aws_iam_role_policy" "cw_ec2_access" {
  name_prefix = "cw_ec2_access"
  role = "${aws_iam_role.cw_automation_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:TerminateInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:RebootInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:StopInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
