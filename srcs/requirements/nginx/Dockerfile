# Base image for Docker container.
FROM debian:bullseye

# Working directory.
WORKDIR /home

# Transfers the script to container's local bin.
COPY tools/nginx_dependencies.sh /usr/local/bin/nginx_dependencies.sh

# Listening connections on exposed port;
EXPOSE 443

RUN	chmod +x /usr/local/bin/nginx_dependencies.sh
RUN /usr/local/bin/nginx_dependencies.sh

# Makes sure to run nginx foreground (main process).
CMD ["nginx", "-g", "daemon off;"]
