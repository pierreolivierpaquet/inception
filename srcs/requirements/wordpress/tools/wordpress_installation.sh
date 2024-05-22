#!/bin/bash

set -e

# https://make.wordpress.org/cli/handbook/guides/installing/
cd /usr/local/bin \
&& curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
&& php wp-cli.phar --info \
&& chmod +x wp-cli.phar \
&& mv wp-cli.phar wp \
&& wp --info
#&& echo -e "wp() {\n\tcommand wp \"\$@\" --allow-root\n}" >> ~/.bashrc

#source ~/.bashrc

# # https://make.wordpress.org/cli/handbook/how-to/how-to-install/
# wp core download	--allow-root \
# 					--path=${WP_CONFIG_FILE_PATH}

# cd ${WP_CONFIG_FILE_PATH} \
# && wp config create	--allow-root \
# 					--dbname=$(cat ${DB_NAME_FILE}) \
# 					--dbuser=$(cat ${DB_USER_FILE}) \
# 					--dbpass=$(cat ${DB_PW_USER_FILE}) \
# 					--dbhost=${DB_HOSTNAME} \
# 					--path=${WP_CONFIG_FILE_PATH}

# # # https://make.wordpress.org/cli/handbook/guides/quick-start/
# wp core install	--allow-root \
# 				--url=${WP_DOMAIN_NAME} \
# 				--title=${WP_TITLE} \
# 				--admin_user=$(cat ${WP_ADMIN_USER_FILE}) \
# 				--admin_password=$(cat ${WP_PW_ADMIN_USER_FILE}) \
# 				--admin_email=$(cat ${WP_EMAIL_ADMIN_USER_FILE})

exec $@
