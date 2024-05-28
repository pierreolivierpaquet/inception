#!/bin/bash

# Installation of the Wordpress Command Line.
# https://make.wordpress.org/cli/handbook/guides/installing/
cd /usr/local/bin \
&& curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
&& php wp-cli.phar --info \
&& chmod +x wp-cli.phar \
&& mv wp-cli.phar wp \
&& wp --info

# Downloading Wordpress website.
# https://make.wordpress.org/cli/handbook/how-to/how-to-install/
wp core download	--allow-root \
					--path=${WP_CONFIG_FILE_PATH}

# Function to check database connection.
check_db_connection() {
    mysql -h${DB_HOSTNAME} -u$(cat ${DB_USER_FILE}) -p$(cat ${DB_PW_USER_FILE}) -e "show databases;"
    return $?
}

# Attempts to connect to database.
for TRIES in {1..25}
do
	if check_db_connection
	then
		break
	fi
	echo "attemp(s) to connect to database: ${TRIES}"
	sleep 2
done

if [ ! -f "${WP_CONFIG_FILE_PATH}/wp-config.php" ]; then \
	# https://developer.wordpress.org/cli/commands/config/create/
	cd ${WP_CONFIG_FILE_PATH} \
	&& wp config create	--allow-root \
						--dbname=$(cat ${DB_NAME_FILE}) \
						--dbuser=$(cat ${DB_USER_FILE}) \
						--dbpass=$(cat ${DB_PW_USER_FILE}) \
						--dbhost=${DB_HOSTNAME} \
						--path=${WP_CONFIG_FILE_PATH}

	# Installation of the website.
	# https://make.wordpress.org/cli/handbook/guides/quick-start/
	wp core install	--allow-root \
					--path=${WP_CONFIG_FILE_PATH} \
					--url=127.0.0.1:8080 \
					--title=${WP_TITLE} \
					--admin_user=$(cat ${WP_ADMIN_USER_FILE}) \
					--admin_password=$(cat ${WP_PW_ADMIN_USER_FILE}) \
					--admin_email=$(cat ${WP_EMAIL_ADMIN_USER_FILE})
fi

exec $@
