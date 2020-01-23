<!-- 
Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0
-->

- hosts: all
  become: true

  tasks:
  - name: Add the ruser user
    user:
      name: ruser
      comment: RStudio user

  - name: Install RStudio
    yum:
      name: https://download2.rstudio.org/server/centos6/x86_64/rstudio-server-rhel-1.2.5001-x86_64.rpm
      state: present

  - name: Install dependencies
    yum:
      name: 
      - "gcc"
      - "gcc-c++"
      - "gcc-gfortran"
      - "readline-devel"
      - "cairo-devel"
      - "libpng-devel"
      - "libjpeg-devel"
      - "libtiff-devel"
      - "openssl-devel"
      - "libxml2-devel"
      - "xorg-x11-xauth.x86_64"
      - "xorg-x11-server-utils.x86_64"
      - "xterm"
      - "libXt"
      - "libX11-devel"
      - "libXt-devel"
      - "libcurl-devel"
      - "git"
      - "compat-gmp4"
      - "compat-libffi5"
      - "R-core"
      - "R-base"
      - "R-core-devel"
      - "R-devel"

  - name: Install R packages
    shell: /usr/bin/R -e 'install.packages(c("sparklyr", "dplyr", "ggplot2"), repos="http://cran.rstudio.com")'

  - name: Stop R server
    shell: /usr/sbin/rstudio-server stop
    ignore_errors: yes

  - name: Verify R installation
    shell: /usr/sbin/rstudio-server verify-installation
    ignore_errors: yes

  - name: Chmod perms on mnt
    file:
      path: /mnt
      mode: '0777'

  - name: Add environment variables to bashrc
    lineinfile:
      path: /home/ruser/.bashrc
      line: "{{item}}"
    with_items:
      - export SPARK_HOME=/usr/lib/spark
      - export SCALA_HOME=/usr/share/scala
      - export HADOOP_HOME=/usr/lib/hadoop
      - export HADOOP_CONF_DIR=/usr/lib/hadoop/etc/hadoop
      - export JAVA_HOME=/etc/alternatives/jre

  - name: Add environment variables to Renviron
    lineinfile:
      path: /home/ruser/.Renviron
      line: "{{item}}"
      create: yes
    with_items:
      - SPARK_HOME=/usr/lib/spark
      - SCALA_HOME=/usr/share/scala
      - HADOOP_HOME=/usr/lib/hadoop
      - HADOOP_CONF_DIR=/usr/lib/hadoop/etc/hadoop
      - JAVA_HOME=/etc/alternatives/jre

  - name: Add hive var to spark defaults
    lineinfile:
      path: /etc/spark/conf/spark-defaults.conf
      line: spark.sql.catalogImplementation   hive

  - name: Query IP
    shell: /usr/bin/curl -s http://169.254.169.254/latest/meta-data/local-hostname
    args:
      warn: False
    register: dns_out
  - name: Look up DNS
    set_fact:
      dns_name: "{{ dns_out.stdout }}"

  - name: Add RStudio port
    lineinfile:
      path: /etc/rstudio/rserver.conf
      line: www-port=8787
  - name: Add RStudio IP
    lineinfile:
      path: /etc/rstudio/rserver.conf
      line: www-address=127.0.0.1

  - name: Chmod perms on ruser home
    file:
      path: /home/ruser
      owner: ruser
      group: ruser
      recurse: yes

  - name: Start R server
    shell: /usr/sbin/rstudio-server start

  - name: Create ruser HDFS dir
    shell: /usr/bin/hadoop fs -mkdir /user/ruser
    become: true
    become_user: hadoop
    ignore_errors: yes
  - name: Chown ruser HDFS dir
    shell: /usr/bin/hadoop fs -chown ruser:ruser /user/ruser
    become: true
    become_user: hadoop
    ignore_errors: yes
