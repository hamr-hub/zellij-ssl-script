#!/bin/bash

DOMAIN="${1:-localhost}"
WEB_PORT="${2:-8082}"
CERT_DIR="$HOME/.zellij/ssl"

mkdir -p "$CERT_DIR"

echo "生成自签名证书..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$CERT_DIR/privkey.pem" \
    -out "$CERT_DIR/fullchain.pem" \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=Zellij/CN=$DOMAIN" \
    -addext "subjectAltName=DNS:$DOMAIN,IP:127.0.0.1"

echo "启动 zellij daemon..."
pkill -f "zellij.*server" 2>/dev/null || true
zellij -d &
sleep 2

echo "启动 zellij web (https://$DOMAIN:$WEB_PORT)..."
pkill -f "zellij web" 2>/dev/null || true
zellij web --ip 0.0.0.0 --port "$WEB_PORT" \
    --cert "$CERT_DIR/fullchain.pem" \
    --key "$CERT_DIR/privkey.pem" &

sleep 2
echo "完成! 访问 https://$DOMAIN:$WEB_PORT"
echo "Token: $(zellij web --create-token 2>&1 | grep -oP '\S+: \S+' || true)"
