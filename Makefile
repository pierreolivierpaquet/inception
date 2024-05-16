
SEP := "--------------------------------------------------------------------------------------------"

all: up

up:
	@if [ ! -d /home/ppaquet/data/volume-wordpress ]; then \
		mkdir -p ~/data/volume-wordpress; \
		echo "volume-wordpress created."; \
	fi

	@if [ ! -d /home/ppaquet/data/volume-mariadb ]; then \
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

pdf:
	@open https://cdn.intra.42.fr/pdf/pdf/80716/fr.subject.pdf

.PHONY: all up down clean fclean purge

# ---------------------------------------------------------------------------- #
#
# 1.	Add a rule which makes sure that the data/volume-* directoroies exists
#		(volume-wordpress, volume-mariadb)
#
#
#
#
#