#!/bin/bash

# Updates.
apt update
apt upgrade

# PHP FastCGI [ Process Manager installation ].
apt install php7.4-fpm -y
