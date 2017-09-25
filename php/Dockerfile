FROM alpine:3.6

MAINTAINER "Adam Dodman <adam.dodman@gmx.com>"

RUN addgroup -g 82 -S www-data \
 && adduser -u 82 -D -S -G www-data www-data \
 && apk add --no-cache php7-zip php7-curl php7-fpm php7-sqlite3 php7-pdo_sqlite php7-session php7-json php7-simplexml tini \
 && rm /etc/php7/php-fpm.d/* 

ADD docker.conf /etc/php7/php-fpm.d/

EXPOSE 9000

CMD ["/sbin/tini","--","php-fpm7"]


