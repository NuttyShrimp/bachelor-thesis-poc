# Stage 1: Build frontend assets
FROM node:22-alpine AS frontend
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Build PHP dependencies
FROM composer:2.8 AS composer
WORKDIR /app
COPY composer.json composer.lock* ./
RUN composer install --no-dev --no-interaction --no-scripts --prefer-dist --ignore-platform-reqs
COPY . .
RUN composer dump-autoload --optimize --classmap-authoritative --no-dev

# Stage 3: Final Production Image
FROM php:8.4-fpm-alpine
WORKDIR /var/www/html

# Install required system packages and PHP extensions
RUN apk add --no-cache \
    zip \
    unzip \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    oniguruma-dev \
    libxml2-dev \
    icu-dev \
    libzip-dev \
    postgresql-dev \
    sqlite-dev \
    linux-headers \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    intl \
    zip \
    opcache

# Configure PHP Opcache & JIT for maximum performance
RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && echo "opcache.enable=1" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.enable_cli=1" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.memory_consumption=256" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.interned_strings_buffer=16" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.max_accelerated_files=20000" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.validate_timestamps=0" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.save_comments=1" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.jit=tracing" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "opcache.jit_buffer_size=100M" >> "$PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini" \
    && echo "expose_php=Off" >> "$PHP_INI_DIR/conf.d/security.ini"

# Create directories before copying and set permissions
RUN mkdir -p \
    bootstrap/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/framework/cache/data \
    storage/framework/testing \
    storage/logs \
    && chown -R www-data:www-data /var/www/html

# Switch to www-data so all files are owned correctly
USER www-data

# Copy app files (respecting .dockerignore)
COPY --chown=www-data:www-data . .

# Copy built vendor and frontend assets
COPY --chown=www-data:www-data --from=composer /app/vendor/ vendor/
COPY --chown=www-data:www-data --from=frontend /app/public/build/ public/build/

# Set up environment variables
ENV APP_ENV=production
ENV APP_DEBUG=false

# Cache configuration, but make sure to clean out any old local cache files first!
RUN rm -f bootstrap/cache/*.php \
    && cp .env.example .env \
    && php artisan key:generate \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache \
    && php artisan event:cache

EXPOSE 9000

# Start PHP-FPM
CMD ["php-fpm"]
