FROM php:7.4.20-fpm-alpine3.13

MAINTAINER Amondar-SO

RUN apk update && apk add --no-cache  bash grep nano coreutils curl oniguruma-dev \
    libpng-dev libjpeg-turbo-dev freetype-dev libmcrypt postgresql-dev libxml2-dev libzip-dev imagemagick-dev libtool \
    composer supervisor git freetds freetds-dev \
    icu icu-dev

## CVE-2026-109618 / CVE-2026-109619 (php2shell): PHP 7.4 has no official fixed release.
## Rebuild PHP from the php-src 7.4 security backport branch and make it the source
## docker-php-ext-install builds the extensions below from.
ARG PHP_SECURITY_COMMIT=712e60f9edfd03f0960fc4fc3c2c375f42b90aa2
ARG PHP_SECURITY_SHA256=c85c8cae6cd97c8688eb0bb2385d2341b74606153d19c3c8688183c3bc760d47
RUN set -eux; \
    configureOptions="$(php-config --configure-options)"; \
    apk add --no-cache --virtual .php-rebuild-deps $PHPIZE_DEPS bison argon2-dev curl-dev libedit-dev \
        libsodium-dev linux-headers openssl-dev sqlite-dev; \
    curl -fsSL -o /tmp/php-src.tar.gz "https://github.com/php/php-src/archive/${PHP_SECURITY_COMMIT}.tar.gz"; \
    echo "${PHP_SECURITY_SHA256} */tmp/php-src.tar.gz" | sha256sum -c -; \
    mkdir -p /tmp/php-src; \
    tar -xzf /tmp/php-src.tar.gz -C /tmp/php-src --strip-components=1; \
    cd /tmp/php-src; ./buildconf --force; ./scripts/dev/genfiles; cd /tmp; \
    rm -f /usr/src/php.tar.xz.asc /tmp/php-src.tar.gz; \
    tar -cJf /usr/src/php.tar.xz php-src; \
    rm -rf /tmp/php-src; \
    docker-php-source extract; cd /usr/src/php; \
    export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS"; \
    eval "./configure $configureOptions"; \
    make -j"$(nproc)"; make install; \
    cd /; docker-php-source delete; \
    apk del --no-network .php-rebuild-deps; \
    php -v | grep '^PHP 7\.4\.34-dev'

RUN docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) json mbstring zip pdo pdo_mysql mysqli pdo_pgsql pdo_dblib iconv gd exif xml opcache intl bcmath

ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/

RUN chmod uga+x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions imagick


EXPOSE 80 9000