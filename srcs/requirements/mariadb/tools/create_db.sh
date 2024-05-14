# # Temporary
# CURRENT_PATH="$(pwd)/"
# SECRET_TEMP_PATH="secrets/"

# # Enventually replace for the /run/secrets/ container path. + remove .txt extension.
# SECRET_PATH=${CURRENT_PATH}${SECRET_TEMP_PATH}
SECRET_PATH="/run/secrets/"

# Filename for MYSQL/MARIADB intitialization.
DB_INIT_FILE="/usr/local/bin/init.sql"

# Current script automatically stops if any command returns a non-zero exit status.
set -e

if [ ! -d "/var/lib/mysql/$(cat ${SECRET_PATH}db_name)" ]; then \

	mysqld_safe

	touch ${DB_INIT_FILE}
	echo "CREATE DATABASE IF NOT EXISTS \`$(cat ${SECRET_PATH}db_name)\`;" >> ${DB_INIT_FILE}
	echo "CREATE USER IF NOT EXISTS \`$(cat ${SECRET_PATH}db_user)\`@'192.168.42.3' IDENTIFIED BY '$(cat ${SECRET_PATH}db_pw_user)';" >> ${DB_INIT_FILE}
	echo "GRANT ALL PRIVILEGES ON \`$(cat ${SECRET_PATH}db_name)\`.* TO \`$(cat ${SECRET_PATH}db_user)\`@'192.168.42.3' IDENTIFIED BY '$(cat ${SECRET_PATH}db_pw_user)' WITH GRANT OPTION;" >> ${DB_INIT_FILE}

	# https://www.ibm.com/docs/en/spectrum-lsf-rtm/10.2.0?topic=ssl-configuring-default-root-password-mysqlmariadb
	# Adds a password to root.
	echo "ALTER USER root@'localhost' IDENTIFIED BY '$(cat ${SECRET_PATH}db_pw_root)';" >> ${DB_INIT_FILE}
	echo "FLUSH PRIVILEGES;" >> ${DB_INIT_FILE}

	mysqladmin -u root -p"$DB_ROOT" -S /var/run/mysqld/mysqld.sock shutdown

	mkdir -p /run/mysqld

fi
