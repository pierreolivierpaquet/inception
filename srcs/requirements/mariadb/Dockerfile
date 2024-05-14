
FROM debian:bullseye

WORKDIR /home

COPY tools/mariadb_dependencies.sh /usr/local/bin/mariadb_dependencies.sh
COPY tools/create_db.sh /usr/local/bin/create_db.sh

RUN chmod +x /usr/local/bin/mariadb_dependencies.sh
RUN /usr/local/bin/mariadb_dependencies.sh

RUN chmod +x /usr/local/bin/create_db.sh
RUN /usr/local/bin/create_db.sh

COPY ./config/50-server.cnf /etc/mysql/mariadb.conf.d/

# CMD ["tail", "-f", "/dev/urandom"]
CMD ["mysqld"]
