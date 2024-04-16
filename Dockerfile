FROM ubuntu:22.04

# Basic setup
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata && \
    apt-get install -y --no-install-recommends git curl autoconf automake make libtool pkg-config \
    software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install libpostal base
RUN git clone https://github.com/openvenues/libpostal
WORKDIR /libpostal
RUN ./bootstrap.sh && \
    ./configure --datadir=/opt/libpostal/data && \
    make 2>&1 | grep error && \
    make install

# Install libpostal PHP wrapper
RUN apt-get update && apt-get install -y gpg-agent zip unzip && \
    add-apt-repository ppa:ondrej/php && \
    apt-get install -y --no-install-recommends libbz2-dev apache2 php8.3-fpm php8.3-common php8.3-dev php8.3-bz2 \
    composer php8.3-opcache php8.3-pdo php8.3-xml php8.3-calendar php8.3-ctype php8.3-dom php8.3-exif \
    php8.3-ffi php8.3-fileinfo php8.3-ftp php8.3-gettext php8.3-iconv php8.3-mbstring php8.3-phar \
    php8.3-posix php8.3-readline php8.3-shmop php8.3-simplexml php8.3-sockets php8.3-sysvmsg php8.3-sysvsem \
    php8.3-sysvshm php8.3-tokenizer php8.3-xmlreader php8.3-xmlwriter php8.3-xsl php8.3-curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    mkdir -p /opt/libpostal-php && cd /opt/libpostal-php && git clone https://github.com/openvenues/php-postal .
WORKDIR /opt/libpostal-php
RUN phpize  && \
    ./configure && \
    make && \
    make install && \
    cp /usr/lib/php/20230831/postal.so /etc/php/8.3/mods-available/postal.so && \
    echo "extension = postal.so" >> /etc/php/8.3/cli/php.ini
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Clone php application and expose port
# Apache Configuration
WORKDIR /var/www/libpostal-php
RUN git clone https://github.com/Symeta-Hybrid/libpostal-rest-php.git .
RUN composer install && \
    cp .env.example .env && \
    php artisan key:generate && \
    chown -R www-data:www-data /var/www/libpostal-php && \
    a2dismod mpm_prefork && \
    a2enconf php8.3-fpm && \
    a2enmod rewrite headers actions alias proxy_fcgi setenvif && \
    a2dissite 000-default.conf && \
    a2dissite default-ssl.conf && \
    apt-get update && apt-get install -y nano supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Supervisor config
RUN mkdir -p /run/php/
COPY ./config/apache/libpostal.conf /etc/apache2/sites-available/libpostal.conf
COPY ./config/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY ./config/supervisor/*.conf /etc/supervisor/conf.d/
COPY ./config/php/php.ini /etc/php/8.3/fpm/php.ini

RUN a2dissite 000-default.conf && \
    a2ensite libpostal.conf

# Startup script to change uid/gid (if environment variable passed) and start supervisord in foreground
COPY ./start.sh /start.sh
RUN chmod 755 /start.sh

EXPOSE 80

CMD ["/bin/bash", "/start.sh"]
