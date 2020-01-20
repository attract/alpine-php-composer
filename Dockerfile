FROM php:7.4.1-fpm-alpine3.11

MAINTAINER Amondar-SO

RUN apk update && apk add --no-cache  bash grep nano coreutils curl \
    libpng-dev libjpeg-turbo-dev freetype-dev libmcrypt postgresql-dev libxml2-dev libzip-dev \
    composer supervisor git freetds freetds-dev \
    icu icu-dev

RUN docker-php-ext-configure gd --with-png --with-jpeg --with-freetype \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) json mbstring zip pdo pdo_mysql mysqli pdo_pgsql pdo_dblib iconv gd exif xml opcache intl \
    && composer global require "hirak/prestissimo:^0.3"


EXPOSE 80 9000