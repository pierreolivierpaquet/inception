#!/bin/bash

# Updates.
apt update
apt upgrade
apt install net-tools -y
apt install curl -y
apt install vim -y

# To communicate with the database on mariadb container.
apt install mariadb-client -y

# PHP FastCGI [ FastCGI Process Manager installation ].
apt install php7.4-fpm -y

# https://www.youtube.com/watch?v=ovJ49PTNSb4
mkdir -p /run/php
