FROM php:8.3-fpm-alpine3.19

MAINTAINER Amondar-SO


## Install required packages
RUN apk update && \
    apk add --no-cache  bash htop grep nano coreutils curl oniguruma-dev \
    libpng-dev libjpeg-turbo-dev freetype-dev libmcrypt postgresql-dev libxml2-dev libzip-dev imagemagick-dev libtool \
    supervisor git freetds freetds-dev icu icu-dev

## Install install-php-extensions package
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

## Install PHP packages
RUN chmod uga+x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions imagick gd json mbstring zip pdo pdo_mysql mysqli pdo_pgsql pdo_dblib iconv exif xml opcache intl bcmath fileinfo

## Configure image processing libraries
RUN docker-php-ext-configure gd --with-jpeg --with-freetype && \
    docker-php-ext-configure intl

## Install composer and open swoole
RUN curl -sfL https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer && \
    chmod +x /usr/bin/composer                                                                     && \
    composer self-update --clean-backups 2.6.6                                    && \
    apk add --no-cache linux-headers && \
    apk add --no-cache libstdc++ postgresql-dev libpq && \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS curl-dev openssl-dev pcre-dev pcre2-dev zlib-dev && \
    docker-php-ext-install sockets && \
    docker-php-source extract && \
    mkdir /usr/src/php/ext/openswoole && \
    curl -sfL https://github.com/openswoole/ext-openswoole/archive/v22.1.2.tar.gz -o openswoole.tar.gz && \
    tar xfz openswoole.tar.gz --strip-components=1 -C /usr/src/php/ext/openswoole && \
    docker-php-ext-configure openswoole \
        --enable-http2   \
        --enable-mysqlnd \
        --enable-openssl \
        --enable-sockets --enable-hook-curl --with-postgres && \
    docker-php-ext-install -j$(nproc) --ini-name zzz-docker-php-ext-openswoole.ini openswoole && \
    rm -f openswoole.tar.gz $HOME/.composer/*-old.phar && \
    docker-php-source delete && \
    apk del .build-deps

EXPOSE 80 9000 8000