
FROM debian:bullseye

WORKDIR /home

COPY tools/mariadb_dependencies.sh /usr/local/bin/mariadb_dependencies.sh

RUN chmod +x /usr/local/bin/mariadb_dependencies.sh
RUN /usr/local/bin/mariadb_dependencies.sh

CMD ["mysqld_safe"]
