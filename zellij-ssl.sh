#!/bin/bash

DOMAIN="jetson-local.hamr.top"
EMAIL="1064042411@qq.com"
CERT_DIR="/etc/letsencrypt/live/${DOMAIN}"
WEB_PORT=8082
LOG_FILE="/var/log/zellij-ssl.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

install_certbot() {
    if command -v certbot &> /dev/null; then
        return 0
    fi
    if command -v apt-get &> /dev/null; then
        echo "heyx1234" | sudo -S apt-get update && echo "heyx1234" | sudo -S apt-get install -y certbot python3-certbot-nginx
    fi
}

auth_hook() {
    env | grep CERTBOT_VALIDATION > /tmp/certbot_challenge.txt
    echo "DNS_CHALLENGE=$CERTBOT_VALIDATION" >> /tmp/certbot_challenge.txt
}

cleanup_hook() {
    rm -f /tmp/certbot_challenge.txt
}

stop_zellij() {
    pkill -f "zellij web" 2>/dev/null || true
    sleep 1
}

check_cert_exists() {
    [ -f "${CERT_DIR}/fullchain.pem" ] && [ -f "${CERT_DIR}/privkey.pem" ]
}

get_cert() {
    log "正在获取证书..."
    
    rm -f /tmp/certbot_challenge.txt
    
    echo "heyx1234" | sudo -S certbot certonly --manual \
        --preferred-challenges dns \
        --manual-auth-hook /bin/bash \
        --manual-cleanup-hook /bin/bash \
        -d "${DOMAIN}" \
        --agree-tos \
        -m "${EMAIL}" \
        --non-interactive \
        2>&1
    
    if [ $? -eq 0 ] && check_cert_exists; then
        log "证书获取成功!"
        return 0
    fi
    
    if [ -f /tmp/certbot_challenge.txt ]; then
        CHALLENGE=$(grep DNS_CHALLENGE /tmp/certbot_challenge.txt | cut -d= -f2)
        log "========== 需要添加的 DNS TXT 记录 =========="
        log "名称: _acme-challenge.${DOMAIN}"
        log "值: ${CHALLENGE}"
        log "=============================================="
        echo ""
        echo "请在 DNS 控制台添加以上 TXT 记录,然后运行:"
        echo "  $0 cert2"
        echo ""
    fi
    return 1
}

get_cert2() {
    log "使用已有挑战值获取证书..."
    
    if [ ! -f /tmp/certbot_challenge.txt ]; then
        log "错误: 没有挑战值,请先运行 $0 cert"
        return 1
    fi
    
    CHALLENGE=$(grep DNS_CHALLENGE /tmp/certbot_challenge.txt | cut -d= -f2)
    
    CURRENT_TXT=$(host -t TXT "_acme-challenge.${DOMAIN}" 8.8.8.8 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
    
    if [ "$CURRENT_TXT" != "$CHALLENGE" ]; then
        log "错误: TXT 记录不匹配"
        log "期望: $CHALLENGE"
        log "当前: $CURRENT_TXT"
        return 1
    fi
    
    echo "heyx1234" | sudo -S certbot certonly --manual \
        --preferred-challenges dns \
        --manual-auth-hook /bin/true \
        --manual-cleanup-hook /bin/true \
        -d "${DOMAIN}" \
        --agree-tos \
        -m "${EMAIL}" \
        --non-interactive \
        2>&1
    
    if [ $? -eq 0 ] && check_cert_exists; then
        log "证书获取成功!"
        rm -f /tmp/certbot_challenge.txt
        return 0
    fi
    
    log "获取失败,请检查 DNS 记录"
    return 1
}

start_zellij() {
    if ! check_cert_exists; then
        log "证书不存在,请先运行 $0 cert"
        return 1
    fi
    
    log "启动 zellij web (端口 ${WEB_PORT})..."
    
    nohup zellij web --ip 0.0.0.0 \
        --port "${WEB_PORT}" \
        --cert "${CERT_DIR}/fullchain.pem" \
        --key "${CERT_DIR}/privkey.pem" \
        -d > /tmp/zellij.log 2>&1 &
    
    sleep 3
    
    if pgrep -f "zellij web" > /dev/null; then
        log "启动成功!"
        log "访问地址: https://${DOMAIN}:${WEB_PORT}"
        return 0
    else
        log "启动失败,查看日志: cat /tmp/zellij.log"
        return 1
    fi
}

renew() {
    log "续订证书..."
    stop_zellij
    
    echo "heyx1234" | sudo -S certbot renew --manual --preferred-challenges dns --quiet
    
    if [ $? -eq 0 ]; then
        log "续订成功"
        start_zellij
    else
        log "续订失败"
    fi
}

check_dns() {
    log "当前 DNS 状态:"
    host -t TXT "_acme-challenge.${DOMAIN}" 8.8.8.8 2>/dev/null
}

status() {
    log "=== 状态检查 ==="
    
    if check_cert_exists; then
        EXPIRY=$(echo "heyx1234" | sudo -S certbot certificates -d "${DOMAIN}" 2>/dev/null | grep "Expiry Date" | head -1)
        log "证书: ${EXPIRY:-Valid}"
    else
        log "证书: 未找到"
    fi
    
    if pgrep -f "zellij web" > /dev/null; then
        log "zellij: 运行中"
    else
        log "zellij: 未运行"
    fi
}

setup_cron() {
    SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    CRON_JOB="0 3 * * * ${SCRIPT_PATH} renew >> ${LOG_FILE} 2>&1"
    (crontab -l 2>/dev/null | grep -v "zellij-ssl" || true; echo "$CRON_JOB") | crontab -
    log "自动续订已设置"
}

case "${1}" in
    cert)
        install_certbot
        get_cert
        ;;
    cert2)
        install_certbot
        get_cert2
        ;;
    start)
        start_zellij
        ;;
    stop)
        stop_zellij
        ;;
    restart)
        stop_zellij
        sleep 2
        start_zellij
        ;;
    renew)
        renew
        ;;
    dns)
        check_dns
        ;;
    status)
        status
        ;;
    setup)
        install_certbot
        setup_cron
        start_zellij
        ;;
    *)
        echo "用法: $0 {cert|cert2|start|stop|restart|renew|dns|status|setup}"
        echo ""
        echo "首次部署步骤:"
        echo "  1. $0 cert      # 获取挑战值"
        echo "  2. (添加DNS TXT) # 在DNS控制台添加记录"
        echo "  3. $0 cert2     # 完成证书获取"
        echo "  4. $0 start     # 启动 zellij"
        exit 1
        ;;
esac
