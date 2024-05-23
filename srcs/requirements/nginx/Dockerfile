# Base image for Docker container.
#	https://www.debian.org/releases/
# 		bullseye -> currently oldstable
FROM debian:bullseye

# Working directory (where the commands are executed).
WORKDIR /home

# Transfers the installation script into container's local bin.
COPY tools/nginx_dependencies.sh /usr/local/bin/nginx_dependencies.sh

# Listening connections on exposed port;
EXPOSE 443

RUN	chmod +x /usr/local/bin/nginx_dependencies.sh
RUN /usr/local/bin/nginx_dependencies.sh

COPY config/default /etc/nginx/sites-available/

# Makes sure to run nginx foreground (main process).
#	< -g > : setting up configurations that apply across your entire NGINX environment.
#	< daemon off > : directive used to run NGINX in the foreground, instead
#					of as a daemon (background).
# https://github.com/nginxinc/docker-nginx/blob/9abe4ae472b3332665fad9b12ee146dc242e775c/mainline/debian/Dockerfile
CMD ["nginx", "-g", "daemon off;"]
# CMD ["tail", "-f", "/dev/urandom"]