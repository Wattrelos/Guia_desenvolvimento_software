# 009 - Instalação e Configuração do MariaDB (PostgreSQL alternativo)
Primeiro, vamos definir as variáveis de ambiente que vamos utilizar no arquivo .env.local:

```env
NGINX_PORT=

# Gerenciador do BD via NGINX
PHPMYADMIN_URL=
PHPMYADMIN_PORT=

# Configurações Gerais da Beta Engine

# Status: development/deployment/production
APP_ENV=
APP_DEBUG=
APP_INSTALLED=

# --- Banco de Dados ---
DB_DRIVER=
DB_HOSTNAME=
DB_PORT=
DB_USERNAME=
DB_PASSWORD=
DB_DATABASE=
DB_PREFIX=

# rota /admin ofuscada:
ADMIN_DIR=
JWT_SECRET_KEY=
API_SIGNATURE_SECRET=

# Cache Redis:
REDIS_HOST=
REDIS_PORT=
REDIS_PASSWORD=

# Mensageria:
RABBITMQ_PORT=
RABBITMQ_MANAGEMENT_PORT=
```

## 1. Tutorial para a instalação do MariaDB:
[mariadb-instalacao](/preparando_ambiente_PHP/mariadb-instalacao.md)

