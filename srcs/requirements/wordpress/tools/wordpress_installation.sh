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

# Checking connection to database.
check_db_connection() {
    mysql -h${DB_HOSTNAME} -u$(cat ${DB_USER_FILE}) -p$(cat ${DB_PW_USER_FILE}) -e "show databases;"
    return $?
}

# Attempts to connect to database.
for TRIES in {1..25}
do
	if check_db_connection
	then
		sleep 5
		break
	fi
	echo "attemp(s) to connect to database: ${TRIES}"
	sleep 5
done

if [ ! -f "${WP_CONFIG_FILE_PATH}/wp-config.php" ]; then \
	# Creation of a new configuration file.
	#	https://developer.wordpress.org/cli/commands/config/create/
	cd ${WP_CONFIG_FILE_PATH} \
	&& wp config create	--allow-root \
						--dbname=$(cat ${DB_NAME_FILE}) \
						--dbuser=$(cat ${DB_USER_FILE}) \
						--dbpass=$(cat ${DB_PW_USER_FILE}) \
						--dbhost=${DB_HOSTNAME} \
						--path=${WP_CONFIG_FILE_PATH}

	# Installation of the website.
	#	https://developer.wordpress.org/cli/commands/core/install/
	#	https://make.wordpress.org/cli/handbook/guides/quick-start/
	wp core install	--allow-root \
					--path=${WP_CONFIG_FILE_PATH} \
					--url=${WP_DOMAIN_NAME} \
					--title=${WP_TITLE} \
					--admin_user=$(cat ${WP_ADMIN_FILE}) \
					--admin_password=$(cat ${WP_PW_ADMIN_FILE}) \
					--admin_email=$(cat ${WP_EMAIL_ADMIN_FILE})

	# Creation of a new user.
	#	https://developer.wordpress.org/cli/commands/user/create/
	wp user create	--allow-root \
					--path=${WP_CONFIG_FILE_PATH} \
					$(cat ${WP_USER_FILE}) \
					$(cat ${WP_EMAIL_USER_FILE}) \
					--role=administrator \
					--user_pass=$(cat ${WP_PW_USER_FILE}) \
					--porcelain
fi

exec $@
