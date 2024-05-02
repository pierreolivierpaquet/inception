# Base image for Docker container.
FROM debian:buster

# Transfers the script to container's local bin.
COPY nginx.sh /usr/local/bin/nginx.sh

EXPOSE 443

RUN /usr/local/bin/nginx.sh
# ENTRYPOINT ["/usr/local/bin/nginx.sh"]
CMD ["nginx", "-g", "daemon off;"]
