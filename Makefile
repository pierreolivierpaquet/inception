
SEP := "--------------------------------------------------------------------------------------------"

SRCS_PATH	:=	./srcs/
ENVIRONMENT_FILE	:=	$(SRCS_PATH).env
SECRETS				:=	./secrets

all: up

up: $(ENVIRONMENT_FILE) secrets
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
	@docker compose -f srcs/docker-compose.yml up --build -d 2>&1 | tee -a docker-compose.log | bar > /dev/null

	@echo "$(SEP)"
	@cat docker-compose.log | tail -n 3

down:
	@docker compose -f srcs/docker-compose.yml down

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

re: nuke all

pdf:
	@open https://cdn.intra.42.fr/pdf/pdf/80716/fr.subject.pdf

delete_data:
	@sudo rm -rf /home/ppaquet/data/volume-mariadb/*
	@sudo rm -rf /home/ppaquet/data/volume-wordpress/*

delete_env:
	@rm -rf $(ENVIRONMENT_FILE)

$(ENVIRONMENT_FILE):
	@if [ ! -f $(ENVIRONMENT_FILE) ]; then \
		echo "Generating '$(ENVIRONMENT_FILE)' file."; \
		touch $(ENVIRONMENT_FILE); \
		echo '' >> $(ENVIRONMENT_FILE); \
		echo 'WP_DOMAIN_NAME="${LOGNAME}.42.fr"' >> $(ENVIRONMENT_FILE); \
		echo '' >> $(ENVIRONMENT_FILE); \
		echo 'WP_CONFIG_FILE_PATH="/var/www/wp"' >> $(ENVIRONMENT_FILE); \
		echo 'WP_TITLE="Inception"' >> $(ENVIRONMENT_FILE) ; \
		echo '' >> $(ENVIRONMENT_FILE); \
		echo 'DB_HOSTNAME="mariadb"' >> $(ENVIRONMENT_FILE); \
		echo '' >> $(ENVIRONMENT_FILE); \
		echo '# IPAM' >> $(ENVIRONMENT_FILE); \
		echo 'INCEPTION_SUBNET="192.168.0.0/16"' >> $(ENVIRONMENT_FILE); \
		echo 'INCEPTION_GATEWAY="192.168.0.1"' >> $(ENVIRONMENT_FILE); \
		echo 'NGINX_HOSTIP="192.168.42.2"' >> $(ENVIRONMENT_FILE); \
		echo 'WP_HOSTIP="192.168.42.3"' >> $(ENVIRONMENT_FILE); \
		echo 'DB_HOSTIP="192.168.42.4"' >> $(ENVIRONMENT_FILE); \
		echo '' >> $(ENVIRONMENT_FILE); \
		echo '# SECRETS' >> $(ENVIRONMENT_FILE); \
		echo 'SECRETS_PATH_HOST="../secrets/"' >> $(ENVIRONMENT_FILE); \
		echo 'SECRETS_PATH="/run/secrets/"' >> $(ENVIRONMENT_FILE); \
		echo '' >> $(ENVIRONMENT_FILE); \
		echo 'DB_NAME_SECRET="db_name"' >> $(ENVIRONMENT_FILE); \
		echo 'DB_NAME_FILE="$${SECRETS_PATH}$${DB_NAME_SECRET}"' >> $(ENVIRONMENT_FILE); \
		echo '' >> $(ENVIRONMENT_FILE); \
		echo 'DB_USER_SECRET="db_user"' >> $(ENVIRONMENT_FILE); \
		echo 'DB_USER_FILE="$${SECRETS_PATH}$${DB_USER_SECRET}"' >> $(ENVIRONMENT_FILE); \
		echo '' >> $(ENVIRONMENT_FILE); \
		echo 'DB_PW_ROOT_SECRET="db_pw_root"' >> $(ENVIRONMENT_FILE); \
		echo 'DB_PW_ROOT_FILE="$${SECRETS_PATH}$${DB_PW_ROOT_SECRET}"' >> $(ENVIRONMENT_FILE); \
		echo '' >> $(ENVIRONMENT_FILE); \
		echo 'DB_PW_USER_SECRET="db_pw_user"' >> $(ENVIRONMENT_FILE); \
		echo 'DB_PW_USER_FILE="$${SECRETS_PATH}$${DB_PW_USER_SECRET}"' >> $(ENVIRONMENT_FILE); \
		echo '' >> $(ENVIRONMENT_FILE); \
		echo 'WP_USER_SECRET="wp_user"' >> $(ENVIRONMENT_FILE); \
		echo 'WP_USER_FILE="$${SECRETS_PATH}$${WP_USER_SECRET}"' >> $(ENVIRONMENT_FILE); \
		echo '' >> $(ENVIRONMENT_FILE); \
		echo 'WP_PW_USER_SECRET="wp_pw_user"' >> $(ENVIRONMENT_FILE); \
		echo 'WP_PW_USER_FILE="$${SECRETS_PATH}$${WP_PW_USER_SECRET}"' >> $(ENVIRONMENT_FILE); \
		echo '' >> $(ENVIRONMENT_FILE); \
		echo 'WP_ADMIN_SECRET="wp_admin"' >> $(ENVIRONMENT_FILE); \
		echo 'WP_ADMIN_FILE="$${SECRETS_PATH}$${WP_ADMIN_SECRET}"' >> $(ENVIRONMENT_FILE); \
		echo '' >> $(ENVIRONMENT_FILE); \
		echo 'WP_PW_ADMIN_SECRET="wp_pw_admin"' >> $(ENVIRONMENT_FILE); \
		echo 'WP_PW_ADMIN_FILE="$${SECRETS_PATH}$${WP_PW_ADMIN_SECRET}"' >> $(ENVIRONMENT_FILE); \
		echo '' >> $(ENVIRONMENT_FILE); \
		echo 'WP_EMAIL_USER_SECRET="wp_email_user"' >> $(ENVIRONMENT_FILE); \
		echo 'WP_EMAIL_USER_FILE="$${SECRETS_PATH}$${WP_EMAIL_USER_SECRET}"' >> $(ENVIRONMENT_FILE); \
		echo '' >> $(ENVIRONMENT_FILE); \
		echo 'WP_EMAIL_ADMIN_SECRET="wp_email_admin"' >> $(ENVIRONMENT_FILE); \
		echo 'WP_EMAIL_ADMIN_FILE="$${SECRETS_PATH}$${WP_EMAIL_ADMIN_SECRET}"' >> $(ENVIRONMENT_FILE); \
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
	if [ ! -f "./secrets/$$ARG" ]; then \
		echo -n $(DB_NAME) >> ./secrets/$$ARG; \
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

.PHONY: all up down clean fclean purge
