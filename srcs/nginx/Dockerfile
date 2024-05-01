# Base image for Docker container.
FROM debian:buster

# Transfers the script to container's local bin.
COPY nginx.sh /usr/local/bin/nginx.sh

RUN /usr/local/bin/nginx.sh

EXPOSE 443
