
FROM debian:bullseye

WORKDIR /home

COPY tools/wordpress_dependencies.sh /usr/local/bin/wordpress_dependencies.sh

RUN chmod +x /usr/local/bin/wordpress_dependencies.sh
RUN /usr/local/bin/wordpress_dependencies.sh

CMD ["php-fpm7.4", "-F"]