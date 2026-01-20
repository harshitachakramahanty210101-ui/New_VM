#!/bin/bash
apt-get update
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
echo "Hello from Private VM via Load Balancer" > /var/www/html/index.html