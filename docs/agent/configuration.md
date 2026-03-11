# Configuration Guide

## Configuration Variables (zellij-ssl.sh)

Edit these variables at the top of `zellij-ssl.sh`:

```bash
DOMAIN="jetson-local.hamr.top"      # Your domain name
EMAIL="1064042411@qq.com"           # Your email for Let's Encrypt
CERT_DIR="/etc/letsencrypt/live/${DOMAIN}"
WEB_PORT=8082                        # Zellij web interface port
LOG_FILE="/var/log/zellij-ssl.log"  # Log file location
```

## Command-Line Arguments (zellij-ssl-simple.sh)

```bash
./zellij-ssl-simple.sh [DOMAIN] [PORT]

# Parameters:
#   DOMAIN    - Domain name (default: localhost)
#   PORT      - Web port (default: 8082)
```

## Certificate Storage

- Production (`zellij-ssl.sh`): `/etc/letsencrypt/live/<DOMAIN>/`
- Development (`zellij-ssl-simple.sh`): `$HOME/.zellij/ssl/`

## Important Notes

1. **Hardcoded Password**: The production script contains a hardcoded sudo password (line 22). Remove or secure this before production use.

2. **DNS Setup**: For Let's Encrypt, you must:
   - Point your domain DNS A record to your server IP
   - Add the TXT record shown by `./zellij-ssl.sh cert`

3. **Port Access**: Ensure port 8082 (or your custom port) is open in firewall.

4. **Cron Job**: The `setup` command creates a cron job for automatic renewal at 3 AM daily.
