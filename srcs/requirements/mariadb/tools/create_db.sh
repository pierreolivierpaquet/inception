# Temporary
CURRENT_PATH="$(pwd)/"
SECRET_TEMP_PATH="secrets/"

# Enventually replace for the /run/secrets/ container path. + remove .txt extension.
SECRET_PATH=${CURRENT_PATH}${SECRET_TEMP_PATH}

DB_INIT="init.sql"

# Current script automatically stops if any command returns a non-zero exit status.
set -e

if [ ! -f ${DB_INIT} ]; then \

	touch ${DB_INIT}
	echo "CREATE DATABASE IF NOT EXISTS \`$(cat ${SECRET_PATH}db_name.txt)\`;" >> ${DB_INIT}
	echo "CREATE USER IF NOT EXISTS \`$(cat ${SECRET_PATH}db_user.txt)\`@'192.168.42.3' IDENTIFIED BY \`$(cat ${SECRET_PATH}db_pw_user.txt)\`;" >> ${DB_INIT}
	echo "GRANT ALL PRIVILEGES ON \`$(cat ${SECRET_PATH}db_name.txt)\` TO \`$(cat ${SECRET_PATH}db_user.txt)\`@'192.168.42.3' IDENTIFIED BY '$(cat ${SECRET_PATH}db_pw_user.txt)' WITH GRANT OPTION;" >> ${DB_INIT}

	# https://www.ibm.com/docs/en/spectrum-lsf-rtm/10.2.0?topic=ssl-configuring-default-root-password-mysqlmariadb
	# Adds a password to root.
	echo "ALTER USER root@'localhost' IDENTIFIED BY '$(cat ${SECRET_PATH}db_pw_root.txt)';" >> ${DB_INIT}
	echo "FLUSH PRIVILEGES;" >> ${DB_INIT}
fi
