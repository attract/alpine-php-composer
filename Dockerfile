FROM php:7.4.13-fpm-alpine3.12

MAINTAINER Amondar-SO

RUN apk update && apk add --no-cache  bash grep nano coreutils curl oniguruma-dev \
    libpng-dev libjpeg-turbo-dev freetype-dev libmcrypt postgresql-dev libxml2-dev libzip-dev \
    composer supervisor git freetds freetds-dev \
    icu icu-dev

RUN docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) json mbstring zip pdo pdo_mysql mysqli pdo_pgsql pdo_dblib iconv gd exif xml opcache intl


EXPOSE 80 9000