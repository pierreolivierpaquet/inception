
SEP	:=	"--------------------------------------------------------------------------------------"

SRCS_PATH			:=	./srcs/
ENVIRONMENT_FILE	:=	$(SRCS_PATH).env
SECRETS				:=	./secrets
DOCKER_COMPOSE_FILE	:=	$(SRCS_PATH)docker-compose.yaml
DOCKER_COMPOSE_FILE_BACKUP	:=	$(SRCS_PATH).backup.yaml
HOSTS_FILE			:=	/etc/hosts
HOSTS_FILE_BACKUP	:=	/etc/.hosts_backup


all: up

up: $(ENVIRONMENT_FILE) secrets edit_yaml host
	@if [ ! -d ~/data/volume-wordpress ]; then \
		mkdir -p ~/data/volume-wordpress; \
		echo "volume-wordpress created."; \
	fi

	@if [ ! -d ~/data/volume-mariadb ]; then \
		mkdir -p ~/data/volume-wordpress; \
		echo "volume-wordpress created."; \
	fi

	@echo $(SEP)
	@echo "docker compose logged into 'docker-compose.log'\n"
	@docker compose -f srcs/docker-compose.yaml up --build -d 2>&1 | tee -a docker-compose.log | bar > /dev/null

	@echo "$(SEP)"
	@cat docker-compose.log | tail -n 3

# Adds the domain to the /etc/hosts file if not already registered.
host:
	@if [ ! -f $(HOSTS_FILE_BACKUP) ]; then sudo sh -c 'cp $(HOSTS_FILE) $(HOSTS_FILE_BACKUP)'; fi
	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^LOGIN" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if ! grep '^127.0.0.1' $(HOSTS_FILE) | grep -q $$ARG.42.fr; then \
		export ARG; \
		sudo -E sh -c 'echo "127.0.0.1\t$$ARG"".42.fr" >> $(HOSTS_FILE)'; \
	fi

down:
	@docker compose -f srcs/docker-compose.yaml down

# Stops the running processes using any NGINX, MARIADB, WORDPRESS (original/custom) image.
stop:
	@if docker ps --format "{{.Image}}" | grep -q "nginx"; then \
		echo "$(SEP)"; \
		echo "Stopped Containers [ nginx ]:"; \
		docker stop $$(docker ps --format "{{.ID}}\t{{.Image}}" | grep "nginx" | awk '{print $$1}') ; \
	fi

	@if docker ps --format "{{.Image}}" | grep -q mariadb; then \
		echo "$(SEP)"; \
		echo "Stopped Containers [ mariadb ]:"; \
		docker stop $$(docker ps --format "{{.ID}}\t{{.Image}}" | grep "mariadb" | awk '{print $$1}') ; \
	fi

	@if docker ps --format "{{.Image}}" | grep -q wordpress; then \
		echo "$(SEP)"; \
		echo "Stopped Containers [ wordpress ]:"; \
		docker stop $$(docker ps --format "{{.ID}}\t{{.Image}}" | grep "wordpress" | awk '{print $$1}') ; \
	fi

# Definitely removes processes (running/stopped) using NGINX, MARIADB, WORDPRESS image.
clean: stop
	@if docker ps -a --format "{{.Image}}" | grep -q "nginx"; then \
		echo "$(SEP)"; \
		echo "Deleted processes [ nginx ]:"; \
		docker rm -f $$(docker ps -a --format "{{.ID}}\t{{.Image}}" | grep "nginx" | awk '{print $$1}') ; \
	fi

	@if docker ps -a --format "{{.Image}}" | grep -q "mariadb"; then \
		echo "$(SEP)"; \
		echo "Deleted processes [ mariadb ]:"; \
		docker rm -f $$(docker ps -a --format "{{.ID}}\t{{.Image}}" | grep "mariadb" | awk '{print $$1}') ; \
	fi

	@if docker ps -a --format "{{.Image}}" | grep -q wordpress; then \
		echo "$(SEP)"; \
		echo "Deleted processes [ wordpress ]:"; \
		docker rm -f $$(docker ps -a --format "{{.ID}}\t{{.Image}}" | grep "wordpress" | awk '{print $$1}') ; \
	fi

# Definitely removes processes AND NGINX, MARIADB, WORDPRESS images.
fclean: clean
	@if docker images --format {{.Repository}} | grep -q "nginx"; then \
		docker image rm $$(docker images --format "{{.ID}}\t{{.Repository}}" | grep "nginx" | awk '{print $$1}'); \
	fi

	@if docker images --format {{.Repository}} | grep -q "mariadb"; then \
		docker image rm $$(docker images --format "{{.ID}}\t{{.Repository}}" | grep "mariadb" | awk '{print $$1}'); \
	fi

	@if docker images --format {{.Repository}} | grep -q "wordpress"; then \
		docker image rm $$(docker images --format "{{.ID}}\t{{.Repository}}" | grep "wordpress" | awk '{print $$1}'); \
	fi

	@if [ -f docker-compose.log ]; then \
		rm docker-compose.log; \
	fi

# Destroys ALL processes, removes ALL image(s), custom network(s), volume(s).
purge:
	@if [ -n "$(shell docker ps -qa)" ]; then \
		echo "$(SEP)"; \
		echo "Deleted Processes:"; \
		docker rm -f $$(docker ps -a --format "{{.Names}}"); \
	fi

	@if [ -n "$(shell docker images --format "{{.ID}}")" ]; then \
		echo "$(SEP)"; \
		docker image prune -af; \
	fi

	@if [ -n "$(shell docker volume ls --format "{{.Name}}")" ]; then \
		echo "$(SEP)"; \
		echo "Deleted Volumes:"; \
		docker volume rm $$(docker volume ls --format "{{.Name}}"); \
	fi

	@if [ -n "$(shell docker network ls --filter type=custom --format "{{.Name}}")" ]; then \
		echo "$(SEP)"; \
		docker network prune -f; \
	fi

nuke: fclean purge delete_env delete_secrets delete_data
	@docker system prune --all --force --volumes
# Restores docker-compose.yaml file.
	@rm -rf $(DOCKER_COMPOSE_FILE)
	@mv $(DOCKER_COMPOSE_FILE_BACKUP) $(DOCKER_COMPOSE_FILE)
#	Restores /etc/hosts file.
	@sudo sh -c 'rm -rf $(HOSTS_FILE)'
	@sudo sh -c 'mv $(HOSTS_FILE_BACKUP) $(HOSTS_FILE)'

re: nuke all

delete_data:
	@sudo rm -rf ~/data/volume-mariadb/*
	@sudo rm -rf ~/data/volume-wordpress/*

delete_env:
	@rm -rf $(ENVIRONMENT_FILE)

pdf:
	@open https://cdn.intra.42.fr/pdf/pdf/80716/fr.subject.pdf

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
	@if [ ! -f $(ENVIRONMENT_FILE) ]; then \
		echo -n "$$ENVIRONMENT" > $(ENVIRONMENT_FILE); \
	fi

delete_secrets:
	@rm -rf $(SECRETS)

DB_NAME				:=	$(shell echo -n ${LOGNAME} | tr '[:lower:]' '[:upper:]')_DB_NAME
DB_USER				:=	$(shell echo -n ${LOGNAME} | tr '[:lower:]' '[:upper:]')_DB_USER
DB_PW_ROOT			:=	$(shell cat /dev/urandom | tr -dc '!A-Z0-9' | head -c 10)
DB_PW_USER			:=	$(shell cat /dev/urandom | tr -dc '!A-Z0-9' | head -c 10)
WP_USER				:=	$(shell echo -n ${LOGNAME} | tr '[:lower:]' '[:upper:]')_WP_USER
WP_PW_USER			:=	$(shell cat /dev/urandom | tr -dc '!A-Z0-9' | head -c 10)
WP_ADMIN			:=	$(shell echo -n ${LOGNAME} | tr '[:lower:]' '[:upper:]')_
WP_PW_ADMIN			:=	$(shell cat /dev/urandom | tr -dc '!A-Z0-9' | head -c 10)
WP_EMAIL_USER		:=	${LOGNAME}.user@inception.ca
WP_EMAIL_ADMIN		:=	${LOGNAME}.admin@inception.ca

$(SECRETS): $(ENVIRONMENT_FILE)
# Creates the Database name secret file.
	@if [ ! -d $(SECRETS) ]; then mkdir $(SECRETS); fi
	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_NAME_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if [ ! -f "./secrets/$$ARG" ]; then			\
		echo -n $(DB_NAME) >> ./secrets/$$ARG;	\
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_USER_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if [ ! -f "./secrets/$$ARG" ]; then \
		echo -n $(DB_USER) >> ./secrets/$$ARG; \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_PW_ROOT_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if [ ! -f "./secrets/$$ARG" ]; then \
		echo -n $(DB_PW_ROOT) >> ./secrets/$$ARG; \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_PW_USER_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if [ ! -f "./secrets/$$ARG" ]; then \
		echo -n $(DB_PW_USER) >> ./secrets/$$ARG; \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_USER_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if [ ! -f "./secrets/$$ARG" ]; then \
		echo -n $(WP_USER) >> ./secrets/$$ARG; \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_PW_USER_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if [ ! -f "./secrets/$$ARG" ]; then \
		echo -n $(WP_PW_USER) >> ./secrets/$$ARG; \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_ADMIN_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if [ ! -f "./secrets/$$ARG" ]; then \
		echo -n $(WP_ADMIN) >> ./secrets/$$ARG; \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_PW_ADMIN_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if [ ! -f "./secrets/$$ARG" ]; then \
		echo -n $(WP_PW_ADMIN) >> ./secrets/$$ARG; \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_EMAIL_USER_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if [ ! -f "./secrets/$$ARG" ]; then \
		echo -n $(WP_EMAIL_USER) >> ./secrets/$$ARG; \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_EMAIL_ADMIN_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if [ ! -f "./secrets/$$ARG" ]; then \
		echo -n $(WP_EMAIL_ADMIN) >> ./secrets/$$ARG; \
	fi


edit_yaml:
# Managing a persistent original copy of the docker-compose.yaml file.
	@if [ ! -f $(DOCKER_COMPOSE_FILE_BACKUP) ]; then \
		cp $(DOCKER_COMPOSE_FILE) $(DOCKER_COMPOSE_FILE_BACKUP); \
	fi && if ! diff $(DOCKER_COMPOSE_FILE) $(DOCKER_COMPOSE_FILE_BACKUP); then \
		rm -rf $(DOCKER_COMPOSE_FILE); \
		cp $(DOCKER_COMPOSE_FILE_BACKUP) $(DOCKER_COMPOSE_FILE); \
	fi

# If needed, proceeds to the modification of the secrets declared within the
#	docker-compose.yaml file.
	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_NAME_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then \
		sed -i "s/db_name/$$ARG/" $(DOCKER_COMPOSE_FILE); \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_USER_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then \
		sed -i "s/db_user/$$ARG/" $(DOCKER_COMPOSE_FILE); \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_PW_ROOT_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then \
		sed -i "s/db_pw_root/$$ARG/" $(DOCKER_COMPOSE_FILE); \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^DB_PW_USER_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then \
		sed -i "s/db_pw_user/$$ARG/" $(DOCKER_COMPOSE_FILE); \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_USER_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then \
		sed -i "s/wp_user/$$ARG/" $(DOCKER_COMPOSE_FILE); \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_PW_USER_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then \
		sed -i "s/wp_pw_user/$$ARG/" $(DOCKER_COMPOSE_FILE); \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_ADMIN_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then \
		sed -i "s/wp_admin/$$ARG/" $(DOCKER_COMPOSE_FILE); \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_PW_ADMIN_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then \
		sed -i "s/wp_pw_admin/$$ARG/" $(DOCKER_COMPOSE_FILE); \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_EMAIL_USER_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then \
		sed -i "s/wp_email_user/$$ARG/" $(DOCKER_COMPOSE_FILE); \
	fi

	@ARG=$$(cat $(ENVIRONMENT_FILE) | grep "^WP_EMAIL_ADMIN_SECRET" | awk -F'=' '{print $$2}' | tr -d "\"") && \
	if ! cat $(DOCKER_COMPOSE_FILE) | grep -q "$$ARG"':'; then \
		sed -i "s/wp_email_admin/$$ARG/" $(DOCKER_COMPOSE_FILE); \
	fi

.PHONY: all up down clean fclean purge
