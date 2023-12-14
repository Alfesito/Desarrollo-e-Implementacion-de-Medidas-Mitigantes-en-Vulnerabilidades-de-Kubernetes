# Dockerfile for vulhub/php:8.1-backdoor
FROM alpine:3.14

# Install necessary dependencies
RUN apk --no-cache add \
    php7 \
    php7-cli \
    php7-common \
    php7-json \
    php7-mbstring \
    php7-opcache \
    php7-xml

# Environment variables
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    PHP_INI_DIR="/etc/php7" \
    PHPIZE_DEPS="autoconf dpkg-dev file g++ gcc libc-dev make pkg-config re2c bison"

# Set working directory
WORKDIR /var/www/html

COPY ./index.php .

# Exposed ports
EXPOSE 80

# Command to run the application
CMD ["php", "-S", "0.0.0.0:80", "-t", "/var/www/html"]
