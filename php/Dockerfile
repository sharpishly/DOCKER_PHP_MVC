FROM php:8.2-fpm

RUN docker-php-ext-install pdo pdo_mysql

RUN apt-get update && apt-get install -y cron certbot python3-certbot-nginx

COPY cron/renew_ssl.sh /etc/cron.daily/renew_ssl
RUN chmod +x /etc/cron.daily/renew_ssl
