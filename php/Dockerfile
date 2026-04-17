# Stage 1: Build frontend assets
FROM node:22-alpine AS frontend
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Install production PHP dependencies
FROM composer:2.8 AS vendor
WORKDIR /app
COPY composer.json composer.lock* ./
RUN composer install --no-dev --no-interaction --no-scripts --prefer-dist --ignore-platform-reqs
COPY . .
RUN composer dump-autoload --optimize --classmap-authoritative --no-dev

# Stage 3: PHP-FPM application image
FROM php:8.4-fpm-alpine AS app
WORKDIR /var/www/html

RUN apk add --no-cache \
    curl \
    freetype \
    icu-libs \
    libjpeg-turbo \
    libpng \
    libzip \
    oniguruma \
    postgresql-libs \
    sqlite-libs \
    && apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    freetype-dev \
    icu-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libzip-dev \
    oniguruma-dev \
    postgresql-dev \
    sqlite-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
    bcmath \
    exif \
    gd \
    intl \
    mbstring \
    opcache \
    pcntl \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    zip \
    && apk del .build-deps

RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && { \
        echo "expose_php=Off"; \
        echo "display_errors=Off"; \
        echo "log_errors=On"; \
        echo "memory_limit=512M"; \
    } > "$PHP_INI_DIR/conf.d/zz-app.ini" \
    && { \
        echo "opcache.enable=1"; \
        echo "opcache.enable_cli=0"; \
        echo "opcache.memory_consumption=256"; \
        echo "opcache.interned_strings_buffer=16"; \
        echo "opcache.max_accelerated_files=20000"; \
        echo "opcache.validate_timestamps=0"; \
        echo "opcache.save_comments=1"; \
    } > "$PHP_INI_DIR/conf.d/zz-opcache.ini" \
    && { \
        echo "[www]"; \
        echo "listen = 9000"; \
        echo "listen.mode = 0660"; \
        echo "pm = dynamic"; \
        echo "pm.max_children = 32"; \
        echo "pm.start_servers = 4"; \
        echo "pm.min_spare_servers = 2"; \
        echo "pm.max_spare_servers = 8"; \
        echo "pm.max_requests = 500"; \
        echo "clear_env = no"; \
    } > /usr/local/etc/php-fpm.d/www.conf

COPY --chown=www-data:www-data . .
COPY --chown=www-data:www-data --from=vendor /app/vendor/ vendor/
COPY --chown=www-data:www-data --from=frontend /app/public/build/ public/build/

RUN mkdir -p \
    bootstrap/cache \
    storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/testing \
    storage/framework/views \
    storage/logs \
    && rm -f bootstrap/cache/*.php \
    && chown -R www-data:www-data /var/www/html

USER www-data

ENV APP_ENV=production \
    APP_DEBUG=false

EXPOSE 9000
CMD ["php-fpm", "-F"]

# Stage 4: Nginx web image
FROM nginx:1.27-alpine AS web
WORKDIR /var/www/html

COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY public/ public/
COPY --from=frontend /app/public/build/ public/build/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
