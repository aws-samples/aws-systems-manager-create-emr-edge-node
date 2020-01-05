# Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# Used in tagging to help identify groups of related resources, e.g. dev vs prod
variable "environment" {}

# Identifies the specific project we're working in, e.g. data science team working on sales forecasting
variable "ProjectTag" {}

# Set to the name of an existing S3 bucket where we'll store an Ansible playbook
variable "bucket" {}

# Identifies the region we're working in; used to help construct ARNs, e.g. us-west-2
variable "region" {}
