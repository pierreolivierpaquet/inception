#!/bin/bash

# Filename for MYSQL/MARIADB intitialization.
DB_INIT_FILE="/usr/local/bin/init.sql"

# Current script automatically stops if any command returns a non-zero exit status.
set -e

if [ ! -d "/var/lib/mysql/$(cat ${DB_NAME_FILE})" ]; then

	service mariadb start

	touch ${DB_INIT_FILE}
	echo "CREATE DATABASE IF NOT EXISTS \`$(cat ${DB_NAME_FILE})\`;" >> ${DB_INIT_FILE}
	echo "CREATE USER IF NOT EXISTS \`$(cat ${SECRETS_PATH}db_user)\`@'192.168.42.3' IDENTIFIED BY '$(cat ${SECRETS_PATH}db_pw_user)';" >> ${DB_INIT_FILE}
	echo "GRANT ALL PRIVILEGES ON \`$(cat ${SECRETS_PATH}db_name)\`.* TO \`$(cat ${SECRETS_PATH}db_user)\`@'192.168.42.3' IDENTIFIED BY '$(cat ${SECRETS_PATH}db_pw_user)' WITH GRANT OPTION;" >> ${DB_INIT_FILE}

	# https://www.ibm.com/docs/en/spectrum-lsf-rtm/10.2.0?topic=ssl-configuring-default-root-password-mysqlmariadb
	# Adds a password to root.
	echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '$(cat ${SECRETS_PATH}db_pw_root)';" >> ${DB_INIT_FILE}
	echo "FLUSH PRIVILEGES;" >> ${DB_INIT_FILE}

	mysql < ${DB_INIT_FILE}

	mysqladmin -u root -p$(cat ${SECRETS_PATH}db_pw_root) -S /var/run/mysqld/mysqld.sock shutdown

	mkdir -p /run/mysqld # already exists due to service mariadb start

fi

# Executes ENTRYPOINT arguments (from CMD [...])
exec $@
