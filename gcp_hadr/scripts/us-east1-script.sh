#!/bin/bash
apt-get update
apt-get install -y nginx

cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;
    location / {
        proxy_pass https://v1-dot-${PROJECT_ID}.ue.r.appspot.com;
        proxy_set_header Host v1-dot-${PROJECT_ID}.ue.r.appspot.com;  # Set Host to App Engine URL
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

systemctl restart nginx
