# 🌐 Guia Operacional: Implantação e Configuração de Proxy Reverso Nginx com SSL/TLS e Defesa Perimetral

Este guia orienta o processo de cópia, instalação de certificados SSL/TLS, configuração com defesa perimetral multinível (ADR 017) e ativação do **Nginx** no servidor remoto/VPS (`192.168.1.9`).

---

## 📌 1. Visão Geral e Topologia

O Nginx opera na borda do servidor, recebendo tráfego seguro nas portas `80` (redirecionamento HTTP $\rightarrow$ HTTPS) e `443` (HTTP/2 com terminação TLS) e encaminhando para a aplicação Rust Axum na porta local `127.0.0.1:3001`.

```
[🌐 Navegador / App] 
        │ HTTPS (443) / HTTP/2
        ▼
[🛡️ Nginx Proxy Reverso (192.168.1.9)]
        │ ├── Limite estrito de 16 KB em /api/v1/.../auth/ (Anti-Hash DoS)
        │ ├── Limite geral de 2 MB nas demais rotas (Uploads e BoQ)
        │ └── Forward de headers: X-Real-IP, X-Forwarded-Proto, Host
        ▼ proxy_pass http://127.0.0.1:3001
[⚡ Skanstull (Axum / Rust)]
```

---

## 🔐 2. Passo 1: Provisionamento dos Certificados SSL/TLS

O Nginx exige certificados válidos para iniciar na porta `443`. Escolha o cenário correspondente ao seu ambiente:

### Cenário A: Servidor em Rede Local / Homologação (via `mkcert`)
Ideal para servidores em rede interna ou laboratório (`192.168.1.9`), gerando certificados com cadeado verde sem alertas no navegador:

1. Acesse o servidor remoto:
   ```bash
   ssh deploy@179.198.119.213
   ```

2. Instale o utilitário `mkcert` e as ferramentas NSS:
   ```bash
   sudo apt update && sudo apt install -y mkcert libnss3-tools
   ```

3. Crie a pasta de certificados locais:
   ```bash
   sudo mkdir -p /etc/ssl/localcerts
   ```

4. Gere o certificado incluindo o nome local, localhost e o novo IP (`192.168.1.9`):
   ```bash
   sudo mkcert -cert-file /etc/ssl/localcerts/skanstull.local.pem \
     -key-file /etc/ssl/localcerts/skanstull.local-key.pem \
     skanstull.local www.skanstull.local localhost 127.0.0.1 ::1 192.168.1.9
   ```

5. Aplique permissões defensivas na chave privada:
   ```bash
   sudo chown -R root:root /etc/ssl/localcerts
   sudo chmod 600 /etc/ssl/localcerts/skanstull.local-key.pem
   sudo chmod 644 /etc/ssl/localcerts/skanstull.local.pem
   ```

> [!TIP]
> Para que o seu navegador pessoal reconheça a autoridade certificadora sem avisos de segurança, copie o certificado raiz gerado na VPS (`~/.local/share/mkcert/rootCA.pem`) para a sua máquina de trabalho e instale-o no repositório de certificados do seu sistema operacional.

---

### Cenário B: Servidor VPS Público na Internet (via Let's Encrypt / Certbot)
Caso você esteja apontando um domínio público registrado (ex: `loja.seudominio.com.br`):
```bash
sudo apt update && sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d loja.seudominio.com.br -d www.loja.seudominio.com.br
```

---

## 🚚 3. Passo 2: Envio do Arquivo de Configuração do Nginx

Como a pasta `/etc/nginx/sites-available/` pertence ao `root`, um usuário sem privilégios não pode escrever diretamente nela via SCP. Escolha um dos dois métodos abaixo para enviar o arquivo:

### Método 1: Cópia Direta via Pipeline SSH + `sudo tee` (Recomendado - Sem arquivos temporários soltos)
Na sua **máquina de desenvolvimento local**, execute:

```bash
cat /etc/nginx/sites-available/skanstull | ssh -t deploy@179.198.119.213 "sudo tee /etc/nginx/sites-available/skanstull > /dev/null"
```

---

### Método 2: Cópia Tradicional via `scp`
1. Envie para o diretório `home` do usuário no servidor remoto:
   ```bash
   scp /etc/nginx/sites-available/skanstull deploy@179.198.119.213:~/skanstull.conf
   ```
2. No servidor remoto, mova para o Nginx e ajuste as permissões:
   ```bash
   ssh -t deploy@179.198.119.213 "sudo mv ~/skanstull.conf /etc/nginx/sites-available/skanstull && sudo chown root:root /etc/nginx/sites-available/skanstull"
   ```

---

## 📄 4. Passo 3: Conteúdo Canônico do Arquivo Nginx (`/etc/nginx/sites-available/skanstull`)

Verifique se a configuração no servidor remoto contém os parâmetros modernos de segurança e limites multinível de payload (conforme **ADR 017**):

```nginx
# ==============================================================================
# 1. Redirecionamento HTTP (Porta 80) para HTTPS (Porta 443)
# ==============================================================================
server {
    listen 80;
    listen [::]:80;
    server_name skanstull.local www.skanstull.local localhost 192.168.1.9;

    # Força transição segura permanente (HTTP 301)
    return 301 https://$host$request_uri;
}

# ==============================================================================
# 2. Servidor Seguro HTTPS (Porta 443 com HTTP/2)
# ==============================================================================
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    
    server_name skanstull.local www.skanstull.local localhost 192.168.1.9;

    # 🟢 Limite global da API/Loja: 2 Megabytes (alinhado com DefaultBodyLimit do Axum)
    client_max_body_size 2M;

    # Certificados SSL/TLS gerados pelo mkcert (ou Let's Encrypt)
    ssl_certificate /etc/ssl/localcerts/skanstull.local.pem;
    ssl_certificate_key /etc/ssl/localcerts/skanstull.local-key.pem;

    # Parâmetros modernos de segurança SSL/TLS
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    # Logs de auditoria de borda
    access_log /var/log/nginx/skanstull_access.log;
    error_log /var/log/nginx/skanstull_error.log;

    # --------------------------------------------------------------------------
    # 🔒 Rota 1: Autenticação Sensível (Proteção contra Hash DoS - CWE-400)
    # Intercepta rotas de login/registro (/api/v1/storefront/auth, /api/v1/admin/auth)
    # --------------------------------------------------------------------------
    location ~* ^/api/v1/(storefront/|admin/)?auth/ {
        # 🟢 Limite estrito de 16 KB EXCLUSIVO para credenciais e autenticação
        client_max_body_size 16k;

        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Encaminhamento de IP real e metadados de protocolo
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;

        proxy_read_timeout 60s;
        proxy_send_timeout 60s;
    }

    # --------------------------------------------------------------------------
    # 🌐 Rota 2: Rota Raiz e Demais Recursos da Skanstull
    # Herda os 2M definidos no bloco server (permite fotos, BoQ, checkout, etc.)
    # --------------------------------------------------------------------------
    location / {
        proxy_pass http://127.0.0.1:3001;

        # Suporte a WebSockets / Server-Sent Events (SSE)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Cabeçalhos essenciais de proxy reverso
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;

        proxy_read_timeout 60s;
        proxy_send_timeout 60s;
    }
}
```

---

## ⚡ 5. Passo 4: Ativação, Validação Sintática e Reload

No servidor remoto (`192.168.1.9`):

```bash
# 1. Cria o link simbólico para ativar o site
sudo ln -sf /etc/nginx/sites-available/skanstull /etc/nginx/sites-enabled/

# 2. Testa a sintaxe dos arquivos de configuração (MUITO IMPORTANTE)
sudo nginx -t

# 3. Se o teste acima retornar 'syntax is ok', recarrega o Nginx sem derrubar conexões ativas
sudo systemctl reload nginx
```

---

## 🧪 6. Passo 5: Verificação Ponta a Ponta e Diagnóstico

### 6.1. Teste de Redirecionamento HTTP $\rightarrow$ HTTPS
```bash
curl -I http://192.168.1.9/
# Retorno esperado: HTTP/1.1 301 Moved Permanently com Location: https://...
```

### 6.2. Teste de Resposta Segura HTTPS
```bash
# A flag -k é usada caso o certificado mkcert ainda não esteja no repositório de CA local do cliente
curl -k -I https://192.168.1.9/healthz
# Retorno esperado: HTTP/2 200 OK
```

### 6.3. Monitoramento de Logs
Em caso de qualquer anomalia de proxy ou erro 502 Bad Gateway:
```bash
# Monitorar logs de erro do Nginx
sudo tail -f /var/log/nginx/skanstull_error.log

# Monitorar acessos e IPs reais encaminhados
sudo tail -f /var/log/nginx/skanstull_access.log
```





---

# Provisionamento do banco de dados

O envio e execução dos esquemas SQL pertence à etapa de **Provisionamento de Dados (Database Provisioning)**. No ciclo de vida da Skanstull, existem **3 abordagens de mercado** para lidar com o banco de dados na VPS:

```
                  ┌──────────────────────────────────────────────┐
                  │ Como provisionar o Banco de Dados na VPS?     │
                  └───────────────────────┬──────────────────────┘
                                          │
       ┌──────────────────────────────────┼──────────────────────────────────┐
       ▼                                  ▼                                  ▼
[Opção 1: Setup Wizard]        [Opção 2: MySQL Dump]              [Opção 3: Pipe CLI]
Usar o instalador web          Migrar banco existente             Executar sementes via
https://192.168.1.9/setup      mysqldump -> mysql remoto          cat seed_ci.sql | ssh mysql
(Requer schemas em /opt)       (Recomendado p/ Produção)          (Rápido e sem arquivos no disco)
```

---

#### 🟢 Opção 1: Inicialização via Setup Wizard Web (`/setup`)
Se você pretende acessar `https://192.168.1.9/setup` no navegador para que a própria aplicação em Rust crie as tabelas e configure o `.env`:
* O backend Axum precisa ler os schemas e sementes em disco.
* **Atenção:** O motor da Skanstull prioriza [`database/seeds/seed_ci.sql`](file:///var/www/html/Rust-e-commerce-Alpha/database/seeds/seed_ci.sql) (que contém o DDL completo **mais** o catálogo inicial de produtos, categorias, frotas e estados fiscais). Se enviar apenas o `install.sql`, o banco terá apenas as tabelas vazias sem produtos.
* **Como copiar para a VPS:**
  ```bash
  # 1. Cria a estrutura na VPS
  ssh deploy@179.198.119.213 "sudo mkdir -p /opt/skanstull/database/schemas /opt/skanstull/database/seeds"

  # 2. Copia os arquivos de sementes e esquemas
  scp database/schemas/install.sql deploy@179.198.119.213:/tmp/
  scp database/seeds/seed_ci.sql deploy@179.198.119.213:/tmp/

  # 3. Move para a pasta definitiva com permissão para o usuário da aplicação
  ssh -t deploy@179.198.119.213 "sudo mv /tmp/install.sql /opt/skanstull/database/schemas/ && \
    sudo mv /tmp/seed_ci.sql /opt/skanstull/database/seeds/ && \
    sudo chown -R www-data:www-data /opt/skanstull/database && \
    sudo chmod -R 750 /opt/skanstull/database"
  ```

---

#### 🚀 Opção 2: Restauração Direta via MySQL Dump (Recomendada para Produção)
Se você já tem o banco populado e homologado no seu ambiente local e quer transferir o estado exato para a VPS:
1. Gere o dump local:
   ```bash
   mysqldump -u root -p skanstull_db > /tmp/skanstull_prod.sql
   ```
2. Envie e restaure direto no MySQL da VPS:
   ```bash
   scp /tmp/skanstull_prod.sql deploy@179.198.119.213:/tmp/
   ssh -t deploy@179.198.119.213 "mysql -u skanstull_user -p skanstull_db < /tmp/skanstull_prod.sql && rm -f /tmp/skanstull_prod.sql"
   ```
3. Configure `APP_INSTALLED=true` no `/opt/skanstull/.env`.
> [!TIP]
> **Vantagem de Segurança em Produção:** A pasta `/opt/skanstull/database/` nem precisa existir no servidor remoto, diminuindo a superfície de exposição de scripts DDL.

---

#### ⚡ Opção 3: Importação Direta via Pipe SSH (Zero Arquivos Temporários)
Se você quer que o MySQL remoto execute o `seed_ci.sql` oficial sem precisar deixar arquivos soltos no disco da VPS:
```bash
# Executa localmente transmitindo o SQL diretamente para o cliente MySQL remoto:
cat database/seeds/seed_ci.sql | ssh -t deploy@179.198.119.213 "mysql -u skanstull_user -p skanstull_db"
```

---

### Resumo da Organização dos Tutoriais

| Arquivo / Tutorial | Camada de Responsabilidade | O que gerencia? |
| :--- | :--- | :--- |
| [`copy-nginx-config-to-remote.md`](file:///var/www/html/Rust-e-commerce-Alpha/copy-nginx-config-to-remote.md) | **Rede & Borda (Nginx)** | Proxy reverso, portas 80/443, SSL/TLS (`mkcert`/Certbot), limites de upload (ADR 017). |
| [`create-service.md`](file:///var/www/html/Rust-e-commerce-Alpha/create-service.md) | **Aplicação & Daemons (Systemd)** | Binários `/opt/skanstull/api` e `workers`, permissões `www-data`, pastas operacionais (`public`, `templates`, `uploads`). |
| **Provisionamento de Banco (Novo)** | **Persistência (MySQL / Mongo / Redis)** | Criação de usuários do MySQL, importação de `seed_ci.sql` / `install.sql` ou dump. |
