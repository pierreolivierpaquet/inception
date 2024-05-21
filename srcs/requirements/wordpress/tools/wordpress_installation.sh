#!/bin/bash

set -e

# https://make.wordpress.org/cli/handbook/guides/installing/
$(cd /usr/local/bin \
&& curl -o wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
&& chmod +x wp \
#&& echo -e "wp() {\n\tcommand wp \"\$@\" --allow-root\n}" >> ~/.bashrc
)

#source ~/.bashrc

# https://make.wordpress.org/cli/handbook/how-to/how-to-install/
wp core download	--allow-root \
					--path=${WP_CONFIG_FILE_PATH}

wp config create	--allow-root \
					--dbname=$(cat ${DB_NAME_FILE}) \
					--dbuser=$(cat ${DB_USER_FILE}) \
					--dbpass=$(cat ${DB_PW_USER_FILE}) \
					--dbhost=${DB_HOSTNAME} \
					--path="${WP_CONFIG_FILE_PATH}"