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
				--url=ppaquet.42.fr \
				--title=${WP_TITLE} \
				--admin_user=$(cat ${WP_ADMIN_USER_FILE}) \
				--admin_password=$(cat ${WP_PW_ADMIN_USER_FILE}) \
				--admin_email=$(cat ${WP_EMAIL_ADMIN_USER_FILE})

exec $@
