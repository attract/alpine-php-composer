FROM php:8.1.7-fpm-alpine3.16

MAINTAINER Amondar-SO

RUN apk update && apk add --no-cache  bash htop grep nano coreutils curl oniguruma-dev \
    libpng-dev libjpeg-turbo-dev freetype-dev libmcrypt postgresql-dev libxml2-dev libzip-dev imagemagick-dev libtool \
    composer supervisor git freetds freetds-dev \
    icu icu-dev

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod uga+x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions imagick gd json mbstring zip pdo pdo_mysql mysqli pdo_pgsql pdo_dblib iconv exif xml opcache intl bcmath

RUN docker-php-ext-configure gd --with-jpeg --with-freetype && \
    docker-php-ext-configure intl


EXPOSE 80 9000