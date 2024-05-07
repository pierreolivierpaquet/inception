
all: up

up:
	@docker-compose -f srcs/docker-compose.yaml up --build -d

down:
	@docker-compose -f srcs/docker-compose.yaml down

stop:
	@if docker ps | grep nginx 1>/dev/null; then \
		echo -n "Stopping -> "; \
		docker stop nginx; \
	fi
	@if docker ps | grep mariadb 1>/dev/null; then \
		echo -n "Stopping -> "; \
		docker stop mariadb; \
	fi
	@if docker ps | grep wordpress 1>/dev/null; then \
		echo -n "Stopping -> "; \
		docker stop wordpress; \
	fi

clean: stop
	@if docker ps -a | grep nginx 1>/dev/null; then \
		echo -n "Removing -> "; \
		docker rm -f nginx; \
	fi
	@if docker ps -a | grep mariadb 1>/dev/null; then \
		echo -n "Removing -> "; \
		docker rm -f mariadb; \
	fi
	@if docker ps -a | grep wordpress 1>/dev/null; then \
		echo -n "Removing -> "; \
		docker rm -f wordpress; \
	fi

fclean:
	

# RESULT=$(shell docker ps -qa)
destroy:
	@if [ $(shell docker ps -qa | head -n 1) ]; then \
		echo "[ Removing processes: ]"; \
		docker rm -f $$(docker ps -a --format {{.Names}}); \
	fi

	@if [ $(shell docker images --format {{.ID}} | head -n 1) ]; then \
		echo "[ Removing images ]"; \
		# docker image rm $$(docker image ls --format {{.ID}}); \
		docker image prune -af; \
	fi

	@if [ $(shell docker volume ls --format {{.Name}} | head -n 1) ]; then \
		echo ""; \
		docker volume rm $$(docker volume ls --format {{.Name}}); \
	fi

	@if [ $(shell docker network ls --filter type=custom --format {{.Name}} | head -n 1 ) ]; then \
		docker network prune -f ; \
	fi

pdf:
	@open https://cdn.intra.42.fr/pdf/pdf/80716/fr.subject.pdf

.PHONY: all

# ---------------------------------------------------------------------------- #
#
# 1.	Add a rule which makes sure that the data/volume-* directoroies exists
#		(volume-wordpress, volume-mariadb)
#
#
#
#
#