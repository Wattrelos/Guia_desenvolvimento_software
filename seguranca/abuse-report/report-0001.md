# Relatório de Abuso #0001 — `45.138.12.16` (AbuseIPDB)

Este documento consolida a análise do log [logs-2026-11-23T11_35_23.811Z.json](file:///var/www/html/abuse-report/logs-2026-11-23T11_35_23.811Z.json) e apresenta os campos exatos para preencher a denúncia no **AbuseIPDB** (via formulário web ou API v2).

---

## 1. Resumo Forense do Incidente

| Campo | Valor Observado no Log |
| :--- | :--- |
| **IP Infrator (`clientIP`)** | `45.138.12.16` |
| **País (`clientCountryName`)** | `PL` (Polônia) |
| **Total de Requisições** | `174` requisições HTTP `GET` (todas bloqueadas na borda Cloudflare: `edgeResponseStatus: 403`, `originResponseStatus: 0`) |
| **Caminhos Únicos Testados** | `91` paths distintos |
| **Janela Total (UTC)** | `2026-11-23T08:51:29Z` até `2026-11-23T10:53:01Z` |
| **Onda 1 (`prometheus.agsonhos.com.br`)** | `91` requisições entre `2026-11-23T08:51:29Z` e `2026-11-23T09:06:48Z` |
| **Onda 2 (`grafana.agsonhos.com.br`)** | `83` requisições entre `2026-11-23T10:39:29Z` e `2026-11-23T10:53:01Z` |

### Padrões de Ataque Identificados
O host executou varredura automatizada por arquivos sensíveis, credenciais, backups e falhas de CMS:
* **Segredos e Credenciais:** `/.env`, `/.env.prod`, `/.env.production`, `/.env.local`, `/.aws/credentials`, `/service-account.json`, `/credentials.json`, `/.netrc`, `/.npmrc`, `/.pypirc`, `/.git-credentials`, `/.htpasswd`.
* **Repositórios e CI/CD:** `/.git/config`, `/.git/HEAD`, `/.git/logs/HEAD`, `/.svn/wc.db`, `/.github/workflows/deploy.yml`, `/.gitlab-ci.yml`, `/.travis.yml`.
* **Backups de Banco e Configuração:** `/database.php.bak`, `/dbconfig.php`, `/config.php.bak`, `/config.php.old`, `/wp-config.php.bak`, `/wp-config.php.zip`.
* **CMS / Painéis Administrativos:** `/wp-admin/`, `/wp-json/wp/v2/users`, `/xmlrpc.php`, `/wp-content/debug.log`, `/administrator/`.

---

## 2. Como Preencher o Formulário do AbuseIPDB

### 1. IP Address
```text
45.138.12.16
```

### 2. Categories (Seleção Recomendada)
Marque **exatamente** as categorias que correspondem às evidências do log:
* ✅ **`21` — Web App Attack:** varredura automatizada por falhas e endpoints de aplicações web/CMS (`/wp-admin/`, `/wp-json/wp/v2/users`, `/xmlrpc.php`, `/config.php`, `/administrator/`).
* ✅ **`15` — Hacking:** busca deliberada por credenciais, chaves de nuvem e arquivos privados (`/.env`, `/.aws/credentials`, `/.git/config`, `/service-account.json`, `/.htpasswd`).

> [!IMPORTANT]
> **O que NÃO marcar neste caso:**
> * ❌ **`14` (Port Scan):** o log registra tráfego HTTP na camada 7 via Cloudflare, não varredura de portas TCP/UDP.
> * ❌ **`18` (Brute-Force) / `22` (SSH):** todas as entradas são `GET` procurando arquivos/rotas; não há tentativas repetidas de login com credenciais (`POST` em tela de login ou SSH).

### 3. Timestamp (quando aplicável / API)
Use o horário em **UTC** da última ocorrência (ou da janela do ataque):
```text
2026-11-23T10:53:01Z
```

### 4. Comment (Pronto para Copiar — < 1024 caracteres)

> [!TIP]
> **Privacidade operacional (OPSEC):** Os comentários enviados ao AbuseIPDB ficam **públicos** na página do IP. Por padrão, o texto abaixo **omite os subdomínios reais** (`prometheus.*` / `grafana.*`) para não expor sua topologia interna publicamente, mantendo todas as evidências técnicas exigidas (contagem, janela UTC, status HTTP 403 e paths reais).

```text
Automated web vulnerability & credential probing (174 GET requests blocked with HTTP 403 at Cloudflare edge between 2026-11-23T08:51:29Z and 2026-11-23T10:53:01Z across 2 subdomains).
Targeted secrets, VCS metadata, backups & CMS endpoints (91 unique paths):
2026-11-23T09:06:42Z GET /.env (403)
2026-11-23T09:06:42Z GET /.git/config (403)
2026-11-23T09:06:43Z GET /.aws/credentials (403)
2026-11-23T09:06:43Z GET /service-account.json (403)
2026-11-23T10:52:59Z GET /wp-config.php.bak (403)
2026-11-23T10:52:59Z GET /wp-json/wp/v2/users (403)
2026-11-23T10:53:01Z GET /.htpasswd (403)
2026-11-23T10:53:01Z GET /database.php.bak (403)
```

---

## 3. Envio Alternativo via API v2 do AbuseIPDB (Opcional)

Após obter sua API Key no painel do AbuseIPDB (e ter o privilégio de *report* aprovado), o envio equivalente pode ser feito com `curl`:

```bash
curl -sS https://api.abuseipdb.com/api/v2/report \
  --data-urlencode "ip=45.138.12.16" \
  -d "categories=15,21" \
  --data-urlencode "timestamp=2026-11-23T10:53:01Z" \
  --data-urlencode 'comment=Automated web vulnerability & credential probing (174 GET requests blocked with HTTP 403 at Cloudflare edge between 2026-11-23T08:51:29Z and 2026-11-23T10:53:01Z across 2 subdomains).
Targeted secrets, VCS metadata, backups & CMS endpoints (91 unique paths):
2026-11-23T09:06:42Z GET /.env (403)
2026-11-23T09:06:42Z GET /.git/config (403)
2026-11-23T09:06:43Z GET /.aws/credentials (403)
2026-11-23T09:06:43Z GET /service-account.json (403)
2026-11-23T10:52:59Z GET /wp-config.php.bak (403)
2026-11-23T10:52:59Z GET /wp-json/wp/v2/users (403)
2026-11-23T10:53:01Z GET /.htpasswd (403)
2026-11-23T10:53:01Z GET /database.php.bak (403)' \
  -H "Key: $ABUSEIPDB_API_KEY" \
  -H "Accept: application/json"
```

---

## 4. Boas Práticas Aplicadas Neste Relatório

1. **Um único relatório por IP na janela:** em vez de enviar 174 denúncias individuais, os eventos das duas ondas foram consolidados em 1 registro (o AbuseIPDB também aplica *cooldown* mínimo de 15 minutos por IP).
2. **Amostra representativa em vez do JSON inteiro:** o campo de comentário tem limite prático de tamanho e legibilidade; listar 8 caminhos críticos com timestamps exatos em UTC comprova a intenção maliciosa com clareza.
3. **Confirmação de ausência de falso positivo:** o path `/` apareceu apenas junto da varredura de 91 endpoints maliciosos (`.env`, `.aws/credentials`, `.git/config`, `wp-config.php.bak`), descartando tráfego legítimo ou *crawlers* de busca.
