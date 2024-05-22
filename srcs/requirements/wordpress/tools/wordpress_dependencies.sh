#!/bin/bash

# Updates.
apt update
apt upgrade
apt install net-tools -y
apt install vim -y

# To download the wordpress website installation script.
apt install curl -y

# To communicate with the database on mariadb container.
apt install mariadb-client -y

# PHP FastCGI [ FastCGI Process Manager installation ].
apt install php7.4-fpm -y
# For wp config create call.
apt install php-mysqli -y
# For wordpress
apt install -y php7.4

# https://www.youtube.com/watch?v=ovJ49PTNSb4
mkdir -p /run/php
