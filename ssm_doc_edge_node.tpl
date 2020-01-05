<!-- 
Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0
-->
---
description: Set up an EMR edge node with RStudio
schemaVersion: "0.3"
assumeRole: "${SSMRoleArn}"
parameters:
  MasterNodeId:
    type: String
    description: EMR master node ID 
    default: ""
  SubnetId:
    type: String
    description: Subnet for edge node
    default: ""
  QuickIdentifier:
    type: String
    description: Provides an easy way to identify the edge node using a Name tag
    default: "Edge Node with RStudio"
mainSteps:
- name: get_sg_id
  action: aws:executeAwsApi
  inputs:
    Service: ec2
    Api: DescribeInstances
    InstanceIds:
    - "{{MasterNodeId}}"
  outputs:
  - Name: SgId
    Selector: "$.Reservations[0].Instances[0].SecurityGroups[0].GroupId"
    Type: "String"
- name: create_ami
  action: aws:createImage
  maxAttempts: 1
  timeoutSeconds: 1200
  onFailure: Abort
  inputs:
    InstanceId: "{{MasterNodeId}}"
    ImageName: AMI Created on{{global:DATE_TIME}}
    NoReboot: true
- name: launch_ami
  action: aws:runInstances
  maxAttempts: 1
  timeoutSeconds: 1200
  onFailure: Abort
  inputs:
    ImageId: "{{create_ami.ImageId}}"
    InstanceType: "m5.xlarge"
    MinInstanceCount: 1
    MaxInstanceCount: 1
    IamInstanceProfileArn: "${InstanceProfileArn}"
    SecurityGroupIds:
      - "{{get_sg_id.SgId}}"
    SubnetId: "{{SubnetId}}"
    TagSpecifications:
    - ResourceType: instance
      Tags:
      - Key: Name
        Value: "{{QuickIdentifier}}"
      - Key: EMRMasterCreatedFrom
        Value: "{{MasterNodeId}}"
      - Key: Project
        Value: "${Project}"
      - Key: Environment
        Value: "${Environment}"
  outputs:
  - Name: iid
    Selector: "$.InstanceIds[0]"
    Type: "String"
- name: updateSSMAgent
  action: aws:runCommand
  inputs:
    DocumentName: AWS-UpdateSSMAgent
    InstanceIds:
    - "{{launch_ami.iid}}"
- name: installPip
  action: aws:runCommand
  inputs:
    DocumentName: AWS-RunShellScript
    InstanceIds:
    - "{{launch_ami.iid}}"
    Parameters:
        commands: 
        - pip install ansible boto3 botocore
- name: runPlaybook
  action: aws:runCommand
  inputs:
    DocumentName: AWS-RunAnsiblePlaybook
    InstanceIds:
    - "{{launch_ami.iid}}"
    Parameters:
      playbookurl: "${PlaybookUrl}"
- name: add_recovery
  action: aws:executeAwsApi
  inputs:
    Service: cloudwatch
    Api: PutMetricAlarm
    AlarmName: "Recovery for edge node {{ launch_ami.iid }}"
    ActionsEnabled: true
    AlarmActions: 
    - "arn:aws:automate:${region}:ec2:recover"
    MetricName: "StatusCheckFailed_System"
    Namespace: "AWS/EC2"
    Statistic: "Maximum"
    Dimensions:
    - Name: "InstanceId"
      Value: "{{launch_ami.iid}}"
    Period: 60
    EvaluationPeriods: 2
    Threshold: 1
    ComparisonOperator: "GreaterThanOrEqualToThreshold"
- name: get_edge_dns
  action: aws:executeAwsApi
  inputs:
    Service: ec2
    Api: DescribeInstances
    InstanceIds:
    - "{{launch_ami.iid}}"
  outputs:
  - Name: EdgeNodeDns
    Selector: "$.Reservations[0].Instances[0].PrivateDnsName"
    Type: "String"
  - Name: EdgeNodeInstanceID
    Selector: "$.Reservations[0].Instances[0].InstanceId"
    Type: "String"
