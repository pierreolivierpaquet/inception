#!/bin/bash

apt update
apt upgrade
apt install net-tools -y
apt install curl -y
apt install vim -y

apt install mariadb-server -y

mkdir -p /run/mysqld
