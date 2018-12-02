FROM php:7.2.12-fpm-alpine

MAINTAINER Amondar-SO

RUN apk update && apk add --no-cache  bash grep nano coreutils curl \
    libpng-dev libjpeg-turbo-dev freetype-dev libmcrypt postgresql-dev \
    composer supervisor git

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) json mbstring zip pdo pdo_mysql mysqli pdo_pgsql iconv gd exif xml opcache \
    && composer global require "hirak/prestissimo:^0.3"


EXPOSE 80 9000