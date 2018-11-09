#!/usr/bin/env bash

yum install dos2unix -y
yum install cifs-utils -y

yum check-update -y
yum upgrade -y