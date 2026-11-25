######### supercronic built with a patched Go toolchain (the release binary ships an older Go stdlib)
FROM golang:1.27.4-alpine3.24 AS supercronic
RUN CGO_ENABLED=0 GOBIN=/out go install github.com/aptible/supercronic@v0.2.51

FROM php:8.5.13-fpm-alpine3.24


## Install required packages
RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache  bash htop grep nano coreutils curl oniguruma-dev \
    libpng-dev libjpeg-turbo-dev freetype-dev libmcrypt postgresql-dev libxml2-dev libzip-dev imagemagick-dev libtool \
    supervisor git freetds freetds-dev icu icu-dev py3-pip && \
    pip install --no-cache-dir --break-system-packages setuptools==84.2.1 && \
    apk del --no-cache py3-pip

## Install install-php-extensions package
ADD https://github.com/mlocati/docker-php-extension-installer/releases/download/2.13.2/install-php-extensions /usr/local/bin/

## Install PHP packages
RUN chmod uga+x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions imagick-3.8.1 gd json mbstring zip pdo pdo_mysql mysqli  \
    pdo_pgsql pdo_dblib iconv exif xml opcache intl bcmath fileinfo pcntl

## Configure image processing libraries
RUN docker-php-ext-configure gd --with-jpeg --with-freetype && \
    docker-php-ext-configure intl

######### Install supercronic
COPY --from=supercronic /out/supercronic /usr/local/bin/supercronic-linux-amd64
RUN ln -s /usr/local/bin/supercronic-linux-amd64 /usr/local/bin/supercronic

## Install composer and open swoole
RUN curl -sfL https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer && \
    chmod +x /usr/bin/composer                                                                     && \
    composer self-update --clean-backups 2.11.2                                    && \
    apk add --no-cache linux-headers && \
    apk add --no-cache libstdc++ postgresql-dev libpq && \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS curl-dev openssl-dev pcre-dev pcre2-dev zlib-dev && \
    docker-php-ext-install sockets && \
    docker-php-source extract && \
    mkdir /usr/src/php/ext/openswoole && \
    curl -sfL https://github.com/openswoole/ext-openswoole/archive/v26.11.0.tar.gz -o openswoole.tar.gz && \
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

## Drop build-only and unused packages: the server needs only the runtime libraries of the PHP extensions.
## ImageMagick keeps its jpeg, png, webp, heic, tiff, jp2 and jxl coders; PDF, RAW and SVG coders are dropped with ghostscript, cups and avahi.
RUN apk del --no-cache nano git coreutils tar imagemagick-pdf imagemagick-raw imagemagick-svg imagemagick-pango \
        ghostscript cups-libs avahi-libs jbig2dec libraw librsvg glycin-svg pango cairo imagemagick-dev libpng-dev libjpeg-turbo-dev freetype-dev postgresql-dev \
        libxml2-dev libzip-dev freetds-dev icu-dev oniguruma-dev libtool linux-headers && \
    apk add --no-cache imagemagick-libs libpng libjpeg-turbo freetype libpq libxml2 libzip freetds icu-libs oniguruma && \
    php -r 'exit(extension_loaded("imagick") && extension_loaded("gd") && extension_loaded("intl") && extension_loaded("pdo_pgsql") && extension_loaded("pdo_dblib") && extension_loaded("openswoole") ? 0 : 1);'

## expat 2.11.0 (CVE-2026-124317, CVE-2026-128241, CVE-2026-134703) is released only in Alpine edge; same libexpat.so.1 ABI, nothing to rebuild.
RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main 'libexpat>=2.11.0'

## ImageMagick: refuse XML-based and script coders (SVG through librsvg/libxml2, MSL, MVG, XPS) and remote URLs; raster coders and text drawing stay.
RUN sed -i 's#</policymap>#  <policy domain="coder" rights="none" pattern="{SVG,SVGZ,MSVG,RSVG,MSL,MVG,XPS,TEXT}" />\n  <policy domain="delegate" rights="none" pattern="*" />\n  <policy domain="path" rights="none" pattern="@*" />\n  <policy domain="module" rights="none" pattern="{URL,HTTP,HTTPS,FTP}" />\n</policymap>#' /etc/ImageMagick-7/policy.xml && \
    php -r '$i = new Imagick(); $i->newImage(2, 2, "white"); $i->setImageFormat("png"); exit(strlen($i->getImageBlob()) > 0 ? 0 : 1);'
