#!/bin/bash

# Filename for MYSQL/MARIADB intitialization.
DB_INIT_FILE="/usr/local/bin/init.sql"

# Current script automatically stops if any command returns a non-zero exit status.
set -e

if [ ! -d "/var/lib/mysql/$(cat ${DB_NAME_FILE})" ]; then

	service	mariadb start

	touch ${DB_INIT_FILE}
	echo	"CREATE DATABASE IF NOT EXISTS \`$(cat ${DB_NAME_FILE})\`;" >> ${DB_INIT_FILE}
	echo	"CREATE USER IF NOT EXISTS \`$(cat ${DB_USER_FILE})\`@'192.168.42.3' \
			IDENTIFIED BY '$(cat ${DB_PW_USER_FILE})';" >> ${DB_INIT_FILE}
	echo	"GRANT ALL PRIVILEGES ON \`$(cat ${DB_NAME_FILE})\`.* TO \`$(cat ${DB_USER_FILE})\`@'192.168.42.3' \
			IDENTIFIED BY '$(cat ${DB_PW_USER_FILE})' WITH GRANT OPTION;" >> ${DB_INIT_FILE}

	# https://www.ibm.com/docs/en/spectrum-lsf-rtm/10.2.0?topic=ssl-configuring-default-root-password-mysqlmariadb
	# Adds a password to root.
	echo	"ALTER USER 'root'@'localhost' \
			IDENTIFIED BY '$(cat ${DB_PW_ROOT_FILE})';" >> ${DB_INIT_FILE}
	echo	"FLUSH PRIVILEGES;" >> ${DB_INIT_FILE}

	mysql	< ${DB_INIT_FILE}

	mysqladmin -u	root -p$(cat ${DB_PW_ROOT_FILE}) -S /var/run/mysqld/mysqld.sock shutdown

else

	mkdir -p	/run/mysqld # instead of using mysqld_safe

fi

# Executes ENTRYPOINT arguments (from CMD [...])
exec	$@
