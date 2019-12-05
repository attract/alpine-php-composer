FROM php:7.3.2-fpm-alpine3.9

MAINTAINER Amondar-SO

RUN apk update && apk add --no-cache  bash grep nano coreutils curl \
    libpng-dev libjpeg-turbo-dev freetype-dev libmcrypt postgresql-dev libxml2-dev libzip-dev \
    composer supervisor git freetds freetds-dev \
    icu icu-dev

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) json mbstring zip pdo pdo_mysql mysqli pdo_pgsql pdo_dblib iconv gd exif xml opcache intl \
    && composer global require "hirak/prestissimo:^0.3"


EXPOSE 80 9000