
FROM debian:bullseye

WORKDIR /home

COPY tools/wordpress_dependencies.sh /usr/local/bin/wordpress_dependencies.sh

RUN chmod +x /usr/local/bin/wordpress_dependencies.sh
RUN /usr/local/bin/wordpress_dependencies.sh

COPY config/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# < -F > to run the process in the foreground.
CMD ["php-fpm7.4", "-F"]
