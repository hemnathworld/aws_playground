#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

echo "<h1>Welcome to Web Server in US GOV EAST </h1>" > /var/www/html/index.html
