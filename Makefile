
SEP	:=	\
"--------------------------------------------------------------------------------"

SRCS_PATH					:=	./srcs/
REQUIREMENTS_PATH			:=	/requirements/
ENVIRONMENT_FILE			:=	$(SRCS_PATH).env
SECRETS						:=	./secrets
DOCKER_COMPOSE_FILE			:=	$(SRCS_PATH)docker-compose.yaml
DOCKER_COMPOSE_FILE_BACKUP	:=	$(SRCS_PATH).backup.yaml
HOSTS_FILE					:=	/etc/hosts
HOSTS_FILE_BACKUP			:=	/etc/.hosts_backup
NGINX_CONFIG_FILE			:=	$(SRCS_PATH)$(REQUIREMENTS_PATH)nginx/config/default
NGINX_CONFIG_FILE_BACKUP	:=	$(SRCS_PATH)$(REQUIREMENTS_PATH)nginx/config/.backup
DOCKER_COMPOSE_LOG_FILE		:=	./docker-compose.log

all: up

up: backup $(ENVIRONMENT_FILE) secrets edit_yaml host nginx_config
	@	if [ ! -d ~/data/volume-wordpress ]; then								\
			mkdir -p ~/data/volume-wordpress;									\
			echo "volume-wordpress created.";									\
		fi

	@	if [ ! -d ~/data/volume-mariadb ]; then									\
			mkdir -p ~/data/volume-wordpress;									\
			echo "volume-wordpress created.";									\
		fi

	@	echo $(SEP)
	@	echo "docker compose logged into '$(DOCKER_COMPOSE_LOG_FILE)'\n"
	@	docker compose -f srcs/docker-compose.yaml up --build -d 2>&1			\
			| tee -a $(DOCKER_COMPOSE_LOG_FILE) | bar > /dev/null

	@	echo "$(SEP)"
	@	cat $(DOCKER_COMPOSE_LOG_FILE) | tail -n 3

# Display the docker-compose logs.
log:
	@	if [ -f $(DOCKER_COMPOSE_LOG_FILE) ]; then								\
			cat $(DOCKER_COMPOSE_LOG_FILE);										\
		fi

# Adds the domain to the /etc/hosts file if not already registered.
host: $(ENVIRONMENT_FILE)
	@	if [ ! -f $(HOSTS_FILE_BACKUP) ]; then									\
			sudo sh -c 'cp $(HOSTS_FILE) $(HOSTS_FILE_BACKUP)';					\
		fi
	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^LOGIN"							\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if ! grep '^127.0.0.1' $(HOSTS_FILE) | grep -q $$ARG.42.fr; then		\
			export ARG;															\
			sudo -E sh -c 'echo "127.0.0.1\t$$ARG"".42.fr" >> $(HOSTS_FILE)';	\
		fi

nginx_config: $(ENVIRONMENT_FILE)
	@	if [ ! -f $(NGINX_CONFIG_FILE_BACKUP) ]; then							\
			cp $(NGINX_CONFIG_FILE) $(NGINX_CONFIG_FILE_BACKUP);				\
		fi
	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^LOGIN"							\
			| awk -F'=' '{print $$2}' | tr -d "\"")'\.42\.fr' &&				\
		sed -i "0,/server_name/s/server_name [^;]*/server_name $${ARG}/"		\
			$(NGINX_CONFIG_FILE)

down:
	@	docker compose -f srcs/docker-compose.yaml down

# Stops the running processes using any NGINX, MARIADB, WORDPRESS (original/custom) image.
stop:
	@	if docker ps --format "{{.Image}}" | grep -q "nginx"; then				\
			echo "$(SEP)";														\
			echo "Stopped Containers [ nginx ]:";								\
			docker stop $$(docker ps --format "{{.ID}}\t{{.Image}}"				\
				| grep "nginx" | awk '{print $$1}');							\
		fi

	@	if docker ps --format "{{.Image}}" | grep -q mariadb; then				\
			echo "$(SEP)";														\
			echo "Stopped Containers [ mariadb ]:";								\
			docker stop $$(docker ps --format "{{.ID}}\t{{.Image}}"				\
				| grep "mariadb" | awk '{print $$1}') ;							\
		fi

	@	if docker ps --format "{{.Image}}" | grep -q wordpress; then			\
			echo "$(SEP)";														\
			echo "Stopped Containers [ wordpress ]:";							\
			docker stop $$(docker ps --format "{{.ID}}\t{{.Image}}"				\
				| grep "wordpress" | awk '{print $$1}') ;						\
		fi

# Definitely removes processes (running/stopped) using NGINX, MARIADB, WORDPRESS image.
clean: stop
	@	if docker ps -a --format "{{.Image}}" | grep -q "nginx"; then			\
			echo "$(SEP)";														\
			echo "Deleted processes [ nginx ]:";								\
			docker rm -f $$(docker ps -a --format "{{.ID}}\t{{.Image}}"			\
				| grep "nginx" | awk '{print $$1}');							\
		fi

	@	if docker ps -a --format "{{.Image}}" | grep -q "mariadb"; then			\
			echo "$(SEP)";														\
			echo "Deleted processes [ mariadb ]:";								\
			docker rm -f $$(docker ps -a --format "{{.ID}}\t{{.Image}}"			\
				| grep "mariadb" | awk '{print $$1}');							\
		fi

	@	if docker ps -a --format "{{.Image}}" | grep -q wordpress; then			\
			echo "$(SEP)";														\
			echo "Deleted processes [ wordpress ]:";							\
			docker rm -f $$(docker ps -a --format "{{.ID}}\t{{.Image}}"			\
				| grep "wordpress" | awk '{print $$1}');						\
		fi

# Definitely removes processes AND NGINX, MARIADB, WORDPRESS images.
fclean: clean
	@	if docker images --format {{.Repository}} | grep -q "nginx"; then		\
			docker image rm $$(docker images --format "{{.ID}}\t{{.Repository}}"\
				| grep "nginx" | awk '{print $$1}');							\
		fi

	@	if docker images --format {{.Repository}} | grep -q "mariadb"; then		\
			docker image rm $$(docker images --format "{{.ID}}\t{{.Repository}}"\
				| grep "mariadb" | awk '{print $$1}');							\
		fi

	@	if docker images --format {{.Repository}} | grep -q "wordpress"; then	\
			docker image rm $$(docker images --format "{{.ID}}\t{{.Repository}}"\
				| grep "wordpress" | awk '{print $$1}');						\
		fi

	@	if [ -f $(DOCKER_COMPOSE_LOG_FILE) ]; then								\
			rm $(DOCKER_COMPOSE_LOG_FILE);										\
		fi

# Destroys ALL processes, removes ALL image(s), custom network(s), volume(s).
purge:
	@	if [ -n "$(shell docker ps -qa)" ]; then								\
			echo "$(SEP)";														\
			echo "Deleted Processes:";											\
			docker rm -f $$(docker ps -a --format "{{.Names}}");				\
		fi

	@	if [ -n "$(shell docker images --format "{{.ID}}")" ]; then				\
			echo "$(SEP)";														\
			docker image prune -af;												\
		fi

	@	if [ -n "$(shell docker volume ls --format "{{.Name}}")" ]; then		\
			echo "$(SEP)";														\
			echo "Deleted Volumes:";											\
			docker volume rm $$(docker volume ls --format "{{.Name}}");			\
		fi

	@	if [ -n "$(shell docker network ls										\
			--filter type=custom --format "{{.Name}}")" ]; then					\
			echo "$(SEP)";														\
			docker network prune -f;											\
		fi

nuke: fclean purge delete_env delete_secrets delete_data restore
	@	docker system prune --all --force --volumes
# Restores docker-compose.yaml file.
	@	if [ -f $(DOCKER_COMPOSE_FILE_BACKUP) ]; then							\
			rm -rf $(DOCKER_COMPOSE_FILE);										\
			mv $(DOCKER_COMPOSE_FILE_BACKUP) $(DOCKER_COMPOSE_FILE);			\
		fi
#	Restores /etc/hosts file.
	@	if [ -f $(HOSTS_FILE_BACKUP) ]; then									\
			sudo sh -c 'rm -rf $(HOSTS_FILE)';									\
			sudo sh -c 'mv $(HOSTS_FILE_BACKUP) $(HOSTS_FILE)';					\
		fi
#	Restores the nginx configuration file.
	@	if [ -f $(NGINX_CONFIG_FILE_BACKUP) ]; then								\
			rm -rf $(NGINX_CONFIG_FILE);										\
			mv $(NGINX_CONFIG_FILE_BACKUP) $(NGINX_CONFIG_FILE);				\
		fi

re: nuke all

delete_data:
	@	sudo rm -rf ~/data/volume-mariadb/*
	@	sudo rm -rf ~/data/volume-wordpress/*

delete_env:
	@	rm -rf $(ENVIRONMENT_FILE)

pdf:
	@	open https://cdn.intra.42.fr/pdf/pdf/80716/fr.subject.pdf

define ENVIRONMENT

LOGIN="${LOGNAME}"
WP_DOMAIN_NAME="$${LOGIN}.42.fr"
WP_CONFIG_FILE_PATH="/var/www/wp"
WP_TITLE="Inception"

DB_HOSTNAME="mariadb"

# IPAM
INCEPTION_SUBNET="192.168.0.0/16"
INCEPTION_GATEWAY="192.168.0.1"
NGINX_HOSTIP="192.168.42.2"
WP_HOSTIP="192.168.42.3"
DB_HOSTIP="192.168.42.4"

# SECRETS
SECRETS_PATH_HOST="../secrets/"
SECRETS_PATH="/run/secrets/"

DB_NAME_SECRET="db_name"
DB_NAME_FILE="$${SECRETS_PATH}$${DB_NAME_SECRET}"

DB_USER_SECRET="db_user"
DB_USER_FILE="$${SECRETS_PATH}$${DB_USER_SECRET}"

DB_PW_ROOT_SECRET="db_pw_root"
DB_PW_ROOT_FILE="$${SECRETS_PATH}$${DB_PW_ROOT_SECRET}"

DB_PW_USER_SECRET="db_pw_user"
DB_PW_USER_FILE="$${SECRETS_PATH}$${DB_PW_USER_SECRET}"

WP_USER_SECRET="wp_user"
WP_USER_FILE="$${SECRETS_PATH}$${WP_USER_SECRET}"

WP_PW_USER_SECRET="wp_pw_user"
WP_PW_USER_FILE="$${SECRETS_PATH}$${WP_PW_USER_SECRET}"

WP_ADMIN_SECRET="wp_admin"
WP_ADMIN_FILE="$${SECRETS_PATH}$${WP_ADMIN_SECRET}"

WP_PW_ADMIN_SECRET="wp_pw_admin"
WP_PW_ADMIN_FILE="$${SECRETS_PATH}$${WP_PW_ADMIN_SECRET}"

WP_EMAIL_USER_SECRET="wp_email_user"
WP_EMAIL_USER_FILE="$${SECRETS_PATH}$${WP_EMAIL_USER_SECRET}"

WP_EMAIL_ADMIN_SECRET="wp_email_admin"
WP_EMAIL_ADMIN_FILE="$${SECRETS_PATH}$${WP_EMAIL_ADMIN_SECRET}"

endef
export ENVIRONMENT

$(ENVIRONMENT_FILE):
	@	if [ ! -f $(ENVIRONMENT_FILE) ]; then									\
			echo -n "$$ENVIRONMENT" > $(ENVIRONMENT_FILE);						\
		fi

delete_secrets:
	@	rm -rf $(SECRETS)

# Generates the secrets content.
DB_NAME			:=	$(shell echo -n ${LOGNAME} | tr '[:lower:]' '[:upper:]')_DB_NAME
DB_USER			:=	$(shell echo -n ${LOGNAME} | tr '[:lower:]' '[:upper:]')_DB_USER
DB_PW_ROOT		:=	$(shell cat /dev/urandom | tr -dc '!A-Z0-9' | head -c 10)
DB_PW_USER		:=	$(shell cat /dev/urandom | tr -dc '!A-Z0-9' | head -c 10)
WP_USER			:=	$(shell echo -n ${LOGNAME} | tr '[:lower:]' '[:upper:]')_WP_USER
WP_PW_USER		:=	$(shell cat /dev/urandom | tr -dc '!A-Z0-9' | head -c 10)
WP_ADMIN		:=	$(shell echo -n ${LOGNAME} | tr '[:lower:]' '[:upper:]')_
WP_PW_ADMIN		:=	$(shell cat /dev/urandom | tr -dc '!A-Z0-9' | head -c 10)
WP_EMAIL_USER	:=	${LOGNAME}.user@inception.ca
WP_EMAIL_ADMIN	:=	${LOGNAME}.admin@inception.ca

$(SECRETS): $(ENVIRONMENT_FILE)
# Creates the Database name secret file.
	@	if [ ! -d $(SECRETS) ];													\
			then mkdir $(SECRETS);												\
		fi
	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_NAME_SECRET"					\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if [ ! -f "./secrets/$$ARG" ]; then										\
			echo -n $(DB_NAME) >> ./secrets/$$ARG;								\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_USER_SECRET"					\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if [ ! -f "./secrets/$$ARG" ]; then										\
			echo -n $(DB_USER) >> ./secrets/$$ARG;								\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_PW_ROOT_SECRET"				\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if [ ! -f "./secrets/$$ARG" ]; then										\
			echo -n $(DB_PW_ROOT) >> ./secrets/$$ARG;							\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_PW_USER_SECRET"				\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if [ ! -f "./secrets/$$ARG" ]; then										\
			echo -n $(DB_PW_USER) >> ./secrets/$$ARG;							\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_USER_SECRET"					\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if [ ! -f "./secrets/$$ARG" ]; then										\
			echo -n $(WP_USER) >> ./secrets/$$ARG;								\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_PW_USER_SECRET"				\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if [ ! -f "./secrets/$$ARG" ]; then										\
			echo -n $(WP_PW_USER) >> ./secrets/$$ARG;							\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_ADMIN_SECRET"				\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if [ ! -f "./secrets/$$ARG" ]; then										\
			echo -n $(WP_ADMIN) >> ./secrets/$$ARG;								\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_PW_ADMIN_SECRET"				\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if [ ! -f "./secrets/$$ARG" ]; then										\
			echo -n $(WP_PW_ADMIN) >> ./secrets/$$ARG;							\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_EMAIL_USER_SECRET"			\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if [ ! -f "./secrets/$$ARG" ]; then										\
			echo -n $(WP_EMAIL_USER) >> ./secrets/$$ARG;						\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_EMAIL_ADMIN_SECRET"			\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if [ ! -f "./secrets/$$ARG" ]; then										\
			echo -n $(WP_EMAIL_ADMIN) >> ./secrets/$$ARG;						\
		fi


edit_yaml:
# Managing a persistent original copy of the docker-compose.yaml file.
	@	if [ ! -f $(DOCKER_COMPOSE_FILE_BACKUP) ]; then							\
			cp $(DOCKER_COMPOSE_FILE) $(DOCKER_COMPOSE_FILE_BACKUP);			\
		fi && if ! diff $(DOCKER_COMPOSE_FILE)									\
		$(DOCKER_COMPOSE_FILE_BACKUP); then										\
			rm -rf $(DOCKER_COMPOSE_FILE);										\
			cp $(DOCKER_COMPOSE_FILE_BACKUP) $(DOCKER_COMPOSE_FILE);			\
		fi

# If needed, proceeds to the modification of the secrets declared within the
#	docker-compose.yaml file.
	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_NAME_SECRET"					\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then				\
			sed -i "s/db_name/$$ARG/" $(DOCKER_COMPOSE_FILE);					\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_USER_SECRET"					\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then				\
			sed -i "s/db_user/$$ARG/" $(DOCKER_COMPOSE_FILE);					\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_PW_ROOT_SECRET"				\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then				\
			sed -i "s/db_pw_root/$$ARG/" $(DOCKER_COMPOSE_FILE);				\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_PW_USER_SECRET"				\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then				\
			sed -i "s/db_pw_user/$$ARG/" $(DOCKER_COMPOSE_FILE);				\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_USER_SECRET"					\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then				\
			sed -i "s/wp_user/$$ARG/" $(DOCKER_COMPOSE_FILE);					\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_PW_USER_SECRET"				\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then				\
			sed -i "s/wp_pw_user/$$ARG/" $(DOCKER_COMPOSE_FILE);				\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_ADMIN_SECRET"				\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then				\
			sed -i "s/wp_admin/$$ARG/" $(DOCKER_COMPOSE_FILE);					\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_PW_ADMIN_SECRET"				\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then				\
			sed -i "s/wp_pw_admin/$$ARG/" $(DOCKER_COMPOSE_FILE);				\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_EMAIL_USER_SECRET"			\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then				\
			sed -i "s/wp_email_user/$$ARG/" $(DOCKER_COMPOSE_FILE);				\
		fi

	@	ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_EMAIL_ADMIN_SECRET"			\
			| awk -F'=' '{print $$2}' | tr -d "\"") &&							\
		if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then				\
			sed -i "s/wp_email_admin/$$ARG/" $(DOCKER_COMPOSE_FILE);			\
		fi

# For Makefile itself.
backup:
	@	if [ ! -f ./.Makefile ]; then											\
			cp Makefile .Makefile;												\
		fi

# Restores the Makefile to prevent persistent changes (ex: environment file).
restore:
	@	if [ -f ./.Makefile ]; then												\
		rm Makefile;															\
		mv .Makefile Makefile;													\
	fi

.PHONY: all up log host nginx_config down stop clean fclean purge nuke re		\
		delete_data delete_env pdf $(ENVIRONMENT_FILE) delete_secrets $(SECRETS)\
		edit_yaml backup restore
