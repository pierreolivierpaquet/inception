#!/bin/bash

# Updates.
apt update
apt upgrade
apt install net-tools -y
apt install curl -y
# PHP FastCGI [ Process Manager installation ].
apt install php7.4-fpm -y
