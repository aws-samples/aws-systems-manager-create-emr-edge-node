# Edge node with RStudio

Data scientists who are comfortable working with RStudio and want to use packages like [sparklyr](https://spark.rstudio.com/) to work with Spark through R need an edge node on a Hadoop cluster.  Edge nodes offer good performance compared to pulling data remotely via Livy and also offer convenient access to local Spark and Hive shells.

However, edge nodes are not easy to deploy.  Edge nodes must have the same versions of Hadoop, Spark, Java, and other tools as the Hadoop cluster, and require the same Hadoop configuration as nodes in the cluster.  In order to reduce the effort to deploy edge nodes, this module automatically deploys and edge node configured with a recent version of RStudio.

## Workflow

We use a Systems Manager automation document to perform the following steps automatically:

* Create an AMI from the master node of the EMR cluster.
* Launch a new EC2 instance using that AMI.
* Install the SSM agent on the new instance.
* Install Ansible on the new instance.
* Run an Ansible playbook to install RStudio.
* Add a CloudWatch alarm to recover the node in case of a host failure.

## Deployment

First we run this module to create the SSM document and some associated security settings.  Start by reviewing the variables in `vars.tf` and set or override any settings you need.

    tf init # one time
    tf apply

Now that the document is created, you can execute it through the SSM console.  You'll need to provide the instance ID of the EMR master node, a subnet to place the edge node, and a name for the node.

## Using the edge node

RStudio is installed with a default user name of `ruser`.  You must set the password by logging into the edge node itself and updating the Linux password for `ruser`.

Access is over port 8787.  You'll need to open an SSH tunnel using Session Manager. 

    aws ssm start-session \
      --target instance-id \ # Get this from the output of the automation document
      --document-name AWS-StartPortForwardingSession \
      --parameters '{"portNumber":["8787"], "localPortNumber":["8787"]}'

Then you can access RStudio at `http://localhost:8787`.

## License

Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0
