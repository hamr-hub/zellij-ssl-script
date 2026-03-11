# AGENTS.md

This file provides guidance to codeflicker when working with code in this repository.

## WHY: Purpose and Goals

SSL/TLS certificate management scripts for enabling HTTPS on Zellij terminal multiplexer web interfaces. Provides two scripts: production-grade setup with Let's Encrypt auto-renewal, and simple development setup with self-signed certificates.

## WHAT: Technical Stack

- Language: Bash shell scripts
- External Tools: certbot, openssl, zellij, python3-certbot-nginx
- Key Files:
  - `zellij-ssl.sh` - Production script with Let's Encrypt (226 lines)
  - `zellij-ssl-simple.sh` - Development script with self-signed certs (29 lines)

## HOW: Core Development Workflow

This is a bash script project - no build or test commands. Scripts are run directly.

```bash
# Production script commands
./zellij-ssl.sh cert       # Step 1: Get DNS challenge
./zellij-ssl.sh cert2      # Step 2: Verify DNS & get cert
./zellij-ssl.sh start      # Start zellij web with HTTPS
./zellij-ssl.sh stop       # Stop zellij web
./zellij-ssl.sh restart    # Restart zellij web
./zellij-ssl.sh renew      # Manually renew certificate
./zellij-ssl.sh setup      # Full setup (install, cron, start)
./zellij-ssl.sh status     # Check certificate & service status
./zellij-ssl.sh dns        # Verify DNS TXT record

# Simple/development script
./zellij-ssl-simple.sh                    # Use defaults (localhost:8082)
./zellij-ssl-simple.sh example.com        # Custom domain
./zellij-ssl-simple.sh example.com 9000   # Custom domain & port
```

## Progressive Disclosure

For detailed information, consult these documents as needed:

- `docs/agent/configuration.md` - Configuration variables and customization

**When working on a task, first determine which documentation is relevant, then read only those files.**
