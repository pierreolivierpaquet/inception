
SEP := "--------------------------------------------------------------------------------------------"

all: up

up:
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

# Destroys all processes, removes all image(s), custom network(s), volume(s).
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

nuke: fclean
	@docker system prune --all --force --volumes

re: nuke all

pdf:
	@open https://cdn.intra.42.fr/pdf/pdf/80716/fr.subject.pdf

deletedata:
	@sudo rm -rf /home/ppaquet/data/volume-mariadb/*
	@sudo rm -rf /home/ppaquet/data/volume-wordpress/*

envgen:
	@if [ ! -f ./srcs/.env ]; then \
		echo "Generating '.env' file."; \
		touch ./srcs/.env; \
		echo '' >> ./srcs/.env; \
		echo 'WP_DOMAIN_NAME="$${LOGNAME}.42.fr"' >> ./srcs/.env; \
		echo '' >> ./srcs/.env; \
		echo 'WP_CONFIG_FILE_PATH="/var/www/wp"' >> ./srcs/.env; \
		echo 'WP_TITLE="Inception"' >> ./srcs/.env ; \
		echo '' >> ./srcs/.env; \
		echo 'DB_HOSTNAME="mariadb"' >> ./srcs/.env; \
		echo '' >> ./srcs/.env; \
		echo '# IPAM' >> ./srcs/.env; \
		echo 'INCEPTION_SUBNET="192.168.0.0/16"' >> ./srcs/.env; \
		echo 'INCEPTION_GATEWAY="192.168.0.1"' >> ./srcs/.env; \
		echo 'NGINX_HOSTIP="192.168.42.2"' >> ./srcs/.env; \
		echo 'WP_HOSTIP="192.168.42.3"' >> ./srcs/.env; \
		echo 'DB_HOSTIP="192.168.42.4"' >> ./srcs/.env; \
		echo '' >> ./srcs/.env; \
		echo '# SECRETS' >> ./srcs/.env; \
		echo 'SECRETS_PATH_HOST="../secrets/"' >> ./srcs/.env; \
		echo 'SECRETS_PATH="/run/secrets/"' >> ./srcs/.env; \
		echo '' >> ./srcs/.env; \
		echo 'DB_NAME_SECRET="db_name"' >> ./srcs/.env; \
		echo 'DB_NAME_FILE="$${SECRETS_PATH}$${DB_NAME_SECRET}"' >> ./srcs/.env; \
		echo '' >> ./srcs/.env; \
		echo 'DB_USER_SECRET="db_user"' >> ./srcs/.env; \
		echo 'DB_USER_FILE="$${SECRETS_PATH}$${DB_USER_SECRET}"' >> ./srcs/.env; \
		echo '' >> ./srcs/.env; \
		echo 'DB_PW_ROOT_SECRET="db_pw_root"' >> ./srcs/.env; \
		echo 'DB_PW_ROOT_FILE="$${SECRETS_PATH}$${DB_PW_ROOT_SECRET}"' >> ./srcs/.env; \
		echo '' >> ./srcs/.env; \
		echo 'DB_PW_USER_SECRET="db_pw_user"' >> ./srcs/.env; \
		echo 'DB_PW_USER_FILE="$${SECRETS_PATH}$${DB_PW_USER_SECRET}"' >> ./srcs/.env; \
		echo '' >> ./srcs/.env; \
		echo 'WP_USER_SECRET="wp_user"' >> ./srcs/.env; \
		echo 'WP_USER_FILE="$${SECRETS_PATH}$${WP_USER_SECRET}"' >> ./srcs/.env; \
		echo '' >> ./srcs/.env; \
		echo 'WP_PW_USER_SECRET="wp_pw_user"' >> ./srcs/.env; \
		echo 'WP_PW_USER_FILE="$${SECRETS_PATH}$${WP_PW_USER_SECRET}"' >> ./srcs/.env; \
		echo '' >> ./srcs/.env; \
		echo 'WP_ADMIN_USER_SECRET="wp_admin_user"' >> ./srcs/.env; \
		echo 'WP_ADMIN_USER_FILE="$${SECRETS_PATH}$${WP_ADMIN_USER_SECRET}"' >> ./srcs/.env; \
		echo '' >> ./srcs/.env; \
		echo 'WP_PW_ADMIN_USER_SECRET="wp_pw_admin_user"' >> ./srcs/.env; \
		echo 'WP_PW_ADMIN_USER_FILE="$${SECRETS_PATH}$${WP_PW_ADMIN_USER_SECRET}"' >> ./srcs/.env; \
		echo '' >> ./srcs/.env; \
		echo 'WP_EMAIL_USER_SECRET="wp_email_user"' >> ./srcs/.env; \
		echo 'WP_EMAIL_USER_FILE="$${SECRETS_PATH}$${WP_EMAIL_USER_SECRET}"' >> ./srcs/.env; \
		echo '' >> ./srcs/.env; \
		echo 'WP_EMAIL_ADMIN_USER_SECRET="wp_email_admin_user"' >> ./srcs/.env; \
		echo 'WP_EMAIL_ADMIN_USER_FILE="$${SECRETS_PATH}$${WP_EMAIL_ADMIN_USER_SECRET}"' >> ./srcs/.env; \
	fi

envdel:
	@rm -rf ./srcs/.env

.PHONY: all up down clean fclean purge
