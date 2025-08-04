#!/bin/bash
set -e

echo "Creating .env..."
cat << 'EOF' > .env
MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_DATABASE=your_db
MYSQL_USER=your_user
MYSQL_PASSWORD=your_password
DOMAIN=sharpishly.com
EOF

echo "Creating website/public/index.php..."
mkdir -p website/public
cat << 'EOF' > website/public/index.php
<?php
$pdo = new PDO('mysql:host=db;dbname=' . getenv('MYSQL_DATABASE'), getenv('MYSQL_USER'), getenv('MYSQL_PASSWORD'));
echo "<body style='background:black;color:white'><h1>Hello from PHP!</h1></body>";
?>
EOF

echo "Creating php/Dockerfile..."
mkdir -p php/cron
cat << 'EOF' > php/Dockerfile
FROM php:8.2-fpm

RUN docker-php-ext-install pdo pdo_mysql

RUN apt-get update && apt-get install -y cron certbot python3-certbot-nginx

COPY cron/renew_ssl.sh /etc/cron.daily/renew_ssl
RUN chmod +x /etc/cron.daily/renew_ssl
EOF

echo "Creating php/cron/renew_ssl.sh..."
cat << 'EOF' > php/cron/renew_ssl.sh
#!/bin/bash
certbot renew --quiet --nginx
EOF

echo "Creating nginx/default.conf..."
mkdir -p nginx
cat << 'EOF' > nginx/default.conf
server {
    listen 80;
    server_name sharpishly.com www.sharpishly.com;

    location / {
        root /var/www/sharpishly/website/public;
        index index.php index.html index.htm;
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME /var/www/sharpishly/website/public\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }

    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name sharpishly.com www.sharpishly.com;

    ssl_certificate /etc/letsencrypt/live/sharpishly.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/sharpishly.com/privkey.pem;

    location / {
        root /var/www/sharpishly/website/public;
        index index.php index.html index.htm;
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME /var/www/sharpishly/website/public\$fastcgi_script_name;
    }
}
EOF

echo "Creating docker-compose.yml..."
cat << 'EOF' > docker-compose.yml
version: '3.8'

services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
      - ./website:/var/www/sharpishly/website
      - /etc/letsencrypt:/etc/letsencrypt
    depends_on:
      - php

  php:
    build: ./php
    volumes:
      - ./website:/var/www/sharpishly/website
    env_file: .env

  db:
    image: mysql:8.0
    restart: always
    env_file: .env
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
EOF

echo "✅ All files created."
echo "Next steps:"
echo "1. Point DNS to this server."
echo "2. Run: docker-compose up -d"
echo "3. On host, install certbot and run:"
echo "   sudo apt install certbot python3-certbot-nginx -y"
echo "   sudo certbot --nginx -d sharpishly.com -d www.sharpishly.com"
echo "4. Your site will be available at https://sharpishly.com"
