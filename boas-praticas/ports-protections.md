# Guia de Hardening e Gestão Segura de Portas em Servidores Linux (VPS)
### *Defesa em Profundidade: Firewall Host (UFW), Blindagem de SSH, Isolamento de Banco de Dados, Proxies Reversos e Mitigação Ativa de Port Scans*

> 📌 **Objetivo deste Guia:**  
> Estabelecer um manual operacional e arquitetural definitivo para a proteção de servidores Linux (VPS/Dedicados). Este documento ensina como minimizar a superfície de ataque externa, isolar serviços internos no loopback, blindar o acesso SSH com autenticação por chave assimétrica, mascarar interfaces administrativas e implantar mecanismos ativos de defesa contra varreduras de portas (Fail2Ban e Portsentry).

> [!WARNING]
> **AMBIENTE DE PRODUÇÃO NÃO É LABORATÓRIO**  
> O conteúdo, scripts e configurações contidos neste repositório têm caráter estritamente educacional e de estudo. 
> * **Nunca** execute ou teste estes arquivos diretamente em um ambiente de produção sem validação prévia.
> * Use sempre um ambiente isolado (como um **Sandbox**, máquina virtual ou laboratório de testes).
> * Configurações incorretas de firewall ou SSH podem resultar na perda irrevogável do acesso remoto (*lockout*). Para mais detalhes, consulte o nosso [disclaimer.md](../disclaimer.md).

---

## 🧭 Sumário Executivo
1. [O Princípio do Menor Privilégio e a Superfície de Ataque](#1-o-princípio-do-menor-privilégio-e-a-superfície-de-ataque)
2. [A Topologia Ideal de Portas em uma VPS](#2-a-topologia-ideal-de-portas-em-uma-vps)
3. [Camada 1: Firewall do Host com UFW (Uncomplicated Firewall)](#3-camada-1-firewall-do-host-com-ufw-uncomplicated-firewall)
4. [Camada 2: Isolamento de Bancos de Dados e Serviços Internos (Loopback)](#4-camada-2-isolamento-de-bancos-de-dados-e-serviços-internos-loopback)
5. [Camada 3: Hardening de SSH (Acesso Administrativo Resiliente)](#5-camada-3-hardening-de-ssh-acesso-administrativo-resiliente)
6. [Camada 4: Exposição Segura de Ferramentas Administrativas (phpMyAdmin / PgAdmin)](#6-camada-4-exposição-segura-de-ferramentas-administrativas-phpmyadmin--pgadmin)
7. [Camada 5: Detecção Ativa e Mitigação de Port Scans (Honeypots & Fail2Ban)](#7-camada-5-detecção-ativa-e-mitigação-de-port-scans-honeypots--fail2ban)
8. [DROP vs REJECT: A Psicologia do Bloqueio de Rede](#8-drop-vs-reject-a-psicologia-do-bloqueio-de-rede)
9. [Auditoria e Verificação Prática: Como Testar Sua Própria VPS](#9-auditoria-e-verificação-prática-como-testar-sua-própria-vps)
10. [Checklist Definitivo de Hardening de Portas](#10-checklist-definitivo-de-hardening-de-portas)

---

## 1. O Princípio do Menor Privilégio e a Superfície de Ataque

No momento em que uma nova máquina virtual (VPS) recebe um endereço IPv4 público na internet, ela passa a sofrer varreduras contínuas (*port scans*). Motores de busca globais de dispositivos (como Shodan, Censys e ZoomEye) e botnets automatizadas varrem as 65.535 portas TCP/UDP de blocos inteiros de IP em busca de:
* Portas de banco de dados abertas sem autenticação ou com credenciais padrão (MySQL na 3306, Redis na 6379, Postgres na 5432).
* Portas SSH padrão (22) sujeitas a ataques de dicionário e força bruta massivos.
* Painéis administrativos expostos com vulnerabilidades conhecidas (phpMyAdmin, Portainer, RabbitMQ Management).

```
┌────────────────────────────────────────────────────────────────────────┐
│                   A REALIDADE DA INTERNET PÚBLICA                      │
├────────────────────────────────────────────────────────────────────────┤
│  Varreduras Automatizadas (Masscan, ZMap, Shodan)                      │
│        │                                                               │
│        ▼                                                               │
│  [ Porta 22 Aberta ]   ──► Tentativa de 10.000 senhas/minuto (Bots)   │
│  [ Porta 3306 Aberta ] ──► Tentativa de injeção e força bruta no root  │
│  [ Porta 6379 Aberta ] ──► Exploração de RCE (Remote Code Execution)   │
└────────────────────────────────────────────────────────────────────────┘
```

### O Modelo de Defesa em Profundidade
Para neutralizar esses ataques, a engenharia de segurança aplica o conceito de **Defesa em Profundidade (Defense-in-Depth)**, estruturado em camadas concêntricas:

1. **Camada de Perímetro:** O firewall descarta silenciosamente qualquer pacote destinado a portas não autorizadas.
2. **Camada de Interface:** Serviços internos escutam apenas no endereço local (`127.0.0.1` / Unix Sockets).
3. **Camada de Aplicação:** Acesso a interfaces de administração protegido por rotas mascaradas, SSL obrigatório e autenticação em dois fatores ou HTTP Basic Auth.
4. **Camada Reativa:** Mecanismos como Fail2Ban e Portsentry que detectam abusos e banem o endereço IP atacante dinamicamente.

---

## 2. A Topologia Ideal de Portas em uma VPS

A divisão arquitetural ideal entre serviços públicos e privados em uma VPS deve seguir o modelo abaixo:

```
                            INTERNET PÚBLICA
                                   │
              ┌────────────────────┴────────────────────┐
              │                                         │
        Porta 80 (TCP)                           Porta 443 (TCP)
          HTTP Nativo                             HTTPS Seguro (TLS)
     (Redireciona para 443)                             │
                                                        ▼
                                              ┌───────────────────┐
                                              │   REVERSE PROXY   │
                                              │  (Nginx / Apache) │
                                              └─────────┬─────────┘
                                                        │
                      REDE INTERNA PRIVADA (localhost / 127.0.0.1)
         ┌──────────────────────────────┼──────────────────────────────┐
         ▼                              ▼                              ▼
┌───────────────────┐          ┌───────────────────┐          ┌───────────────────┐
│     Aplicação     │          │   MySQL / Postg.  │          │    Cache Redis    │
│  Node / PHP / Go  │          │   Porta 3306/5432 │          │    Porta 6379     │
│  (Porta 3000/FPM) │          │ (Escuta 127.0.0.1)│          │ (Escuta 127.0.0.1)│
└───────────────────┘          └───────────────────┘          └───────────────────┘
```

| Categoria | Portas | Política de Exposição | Justificativa |
| :--- | :--- | :--- | :--- |
| **Públicas** | `80` (HTTP), `443` (HTTPS) | Abertas para o mundo (`0.0.0.0/0`) | Portas de entrada obrigatórias para os usuários navegarem pelo site ou consumirem APIs com certificado SSL. |
| **Acesso Administrativo** | `22` ou `Porta Customizada` (SSH) | Restrita por Chave Criptográfica / IP Fixo | Canal vital de controle da VPS. Nunca deve aceitar senhas comuns. |
| **Bancos de Dados** | `3306` (MySQL), `5432` (Postgres), `6379` (Redis) | **ESTRITAMENTE LOCAL** (`127.0.0.1`) | O mundo externo não tem motivos para dialogar diretamente com o banco. O acesso é intermediado pela aplicação backend. |
| **Backends de Aplicação** | `3000` (Node), `8000` (Python), `9000` (PHP-FPM) | **ESTRITAMENTE LOCAL** (`127.0.0.1`) | Devem rodar atrás do Reverse Proxy (Nginx), que assume o papel de terminação TLS, balanceamento e cache. |

---

## 3. Camada 1: Firewall do Host com UFW (Uncomplicated Firewall)

O UFW é a interface padrão de gerenciamento de regras de `iptables`/`nftables` no Ubuntu e Debian. A regra de ouro de qualquer firewall corporativo é a **Política de Bloqueio Padrão (Default Deny)**: *Tudo o que não for expressamente permitido deve ser sumariamente bloqueado.*

### 3.1 Procedimento de Configuração Inicial Segura

> ⚠️ **Atenção:** Libere a sua porta SSH **ANTES** de ativar o firewall para evitar perder o acesso remoto ao servidor.

```bash
# 1. Redefinir regras para estado limpo (opcional, use com cautela)
sudo ufw --force reset

# 2. Configurar políticas padrão de segurança
sudo ufw default deny incoming   # Bloqueia qualquer tráfego de entrada não autorizado
sudo ufw default allow outgoing  # Permite que o servidor faça requisições externas (updates, DNS)

# 3. Liberar interface de loopback (essencial para comunicação local)
sudo ufw allow in on lo to any

# 4. Liberar portas Web públicas essenciais
sudo ufw allow 80/tcp comment 'HTTP Publico'
sudo ufw allow 443/tcp comment 'HTTPS Publico'

# 5. Liberar a porta de administração SSH (se alterada, substitua o número)
sudo ufw allow 22/tcp comment 'SSH Administrativo'

# 6. Ativar o firewall
sudo ufw enable

# 7. Verificar o status e as regras ativas
sudo ufw status verbose
```

### 3.2 Restringindo o SSH a um IP Específico (Segurança Máxima)
Se você possui um endereço de IP público fixo no seu escritório ou utiliza uma VPN com IP estático, você pode fechar a porta SSH para todo o resto do planeta:

```bash
# Remove a regra genérica anterior
sudo ufw delete allow 22/tcp

# Permite acesso ao SSH exclusivamente a partir do seu IP
sudo ufw allow from 203.0.113.45 to any port 22 proto tcp comment 'SSH Restrito IP Escritorio'
```

---

## 4. Camada 2: Isolamento de Bancos de Dados e Serviços Internos (Loopback)

Um dos erros mais comuns e perigosos no desenvolvimento é configurar bancos de dados para escutar em `0.0.0.0` (todas as interfaces de rede). Se o firewall falhar temporariamente ou for desativado por um script desavisado, seu banco de dados ficará imediatamente vulnerável.

### 4.1 Configurando o MySQL / MariaDB para Loopback Estrito
Edite o arquivo de configuração do serviço (geralmente em `/etc/mysql/mariadb.conf.d/50-server.cnf` ou `/etc/mysql/my.cnf`):

```ini
[mysqld]
# Garante que o MySQL só aceita conexões vindas do próprio servidor
bind-address = 127.0.0.1
```

Após salvar, reinicie o serviço:
```bash
sudo systemctl restart mariadb  # ou mysql
```

### 4.2 Configurando o PostgreSQL para Loopback Estrito
Edite o arquivo `postgresql.conf` (ex: `/etc/postgresql/16/main/postgresql.conf`):

```ini
listen_addresses = 'localhost'
```

E no arquivo `pg_hba.conf`, certifique-se de que conexões locais são validadas corretamente:
```ini
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    all             all             127.0.0.1/32            scram-sha-256
```

Reinicie o PostgreSQL:
```bash
sudo systemctl restart postgresql
```

### 4.3 Configurando o Redis para Proteção Local
Edite `/etc/redis/redis.conf`:
```ini
bind 127.0.0.1 -::1
protected-mode yes
```

### 4.4 Como Acessar o Banco Remotamente com Segurança: O Túnel SSH
Você não precisa abrir a porta do banco no firewall para gerenciar dados pelo DBeaver, MySQL Workbench ou DataGrip. A abordagem correta da engenharia é o **Túnel SSH com Redirecionamento de Porta Local (Local Port Forwarding)**:

```bash
# Executado no seu computador local:
# Redireciona a porta local 3307 do seu computador para o 127.0.0.1:3306 da VPS
ssh -N -L 3307:127.0.0.1:3306 usuario@ip_da_vps -p 22
```

```
┌────────────────────────────────────────────────────────────────────────┐
│                   O MECANISMO DO TÚNEL SSH (FORWARDING)                │
├────────────────────────────────────────────────────────────────────────┤
│  Seu Computador (DBeaver conecta em localhost:3307)                   │
│         │                                                              │
│         ▼ (Túnel Criptografado na Porta 22 do SSH)                     │
│  Servidor VPS ──► Redireciona internamente para 127.0.0.1:3306         │
└────────────────────────────────────────────────────────────────────────┘
```
* **No seu cliente de banco (DBeaver):** Configure a conexão para Host `127.0.0.1`, Porta `3307`, usuário e senha do banco. A comunicação viaja criptografada dentro da sessão SSH, mantendo a porta 3306 do servidor 100% invisível para a internet.

---

## 5. Camada 3: Hardening de SSH (Acesso Administrativo Resiliente)

Alterar a porta padrão do SSH (de 22 para um número como 2244) é uma medida benéfica para reduzir o "ruído" nos arquivos de log, mas é apenas **segurança por obscuridade**. O verdadeiro endurecimento (*hardening*) do protocolo SSH exige eliminar logins por senha e vetar o acesso direto do usuário `root`.

### 5.1 Passo 1: Criar um Usuário Administrativo Dedicado
Nunca opere o servidor rotineiramente como `root`. Crie um usuário comum com poderes de elevação via `sudo`:

```bash
# 1. Criar novo usuário
sudo adduser adminuser

# 2. Conceder privilégios de sudo
# No Ubuntu/Debian:
sudo usermod -aG sudo adminuser

# No CentOS/RHEL/Rocky Linux:
sudo usermod -aG wheel adminuser
```

### 5.2 Passo 2: Gerar e Instalar Chaves SSH Assimétricas (Ed25519)
Em seu computador de trabalho (cliente), gere um par de chaves usando a curva elíptica **Ed25519** (mais rápida e matematicamente mais segura que RSA legado):

```bash
# Executado no seu computador local:
ssh-keygen -t ed25519 -a 100 -C "adminuser@empresa.com"

# Copiar a chave pública para o servidor VPS
ssh-copy-id -i ~/.ssh/id_ed25519.pub -p 22 adminuser@ip_da_vps
```

### 5.3 Passo 3: Configurar o Daemon do OpenSSH com Regras Estritas
A boa prática em distribuições modernas é criar um arquivo de configuração modular em `/etc/ssh/sshd_config.d/01-hardening.conf`:

```bash
sudo nano /etc/ssh/sshd_config.d/01-hardening.conf
```

Insira as diretivas recomendadas:
```ini
# Porta customizada (opcional, escolha entre 1024 e 65535)
Port 2244

# Desativar login direto do superusuário root
PermitRootLogin no

# Desativar completamente autenticação por senhas (força o uso de chaves)
PasswordAuthentication no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no

# Exigir autenticação por chave pública
PubkeyAuthentication yes

# Limitar o número máximo de tentativas de autenticação antes de desconectar
MaxAuthTries 3

# Desativar redirecionamento gráfico e portas não utilizadas
X11Forwarding no

# Restringir quem tem permissão para logar via SSH
AllowUsers adminuser
```

### 5.4 Passo 4: Validar a Sintaxe e Reiniciar o Serviço

> 🛡️ **Regra de Ouro da Conectividade:**  
> **JAMAIS feche a janela atual do terminal** antes de validar a sintaxe e testar a conexão em uma **segunda janela separada**.

```bash
# 1. Testar se a sintaxe do arquivo de configuração está correta (não deve retornar erros)
sudo sshd -t

# 2. Se alterou a porta, libere-a no firewall ANTES de reiniciar o SSH!
sudo ufw allow 2244/tcp comment 'SSH Nova Porta'

# 3. Reiniciar o serviço SSH
sudo systemctl restart ssh   # Ubuntu/Debian
# sudo systemctl restart sshd # CentOS/RHEL

# 4. TESTE O ACESSO EM OUTRA ABA DO TERMINAL:
# ssh -p 2244 adminuser@ip_da_vps
```

---

## 6. Camada 4: Exposição Segura de Ferramentas Administrativas (phpMyAdmin / PgAdmin)

Ferramentas web de administração de bancos de dados são os alvos prediletos de bots maliciosos que realizam varreduras automáticas em busca de `/phpmyadmin/`, `/pma/`, `/admin/` ou `/mysql/`.

Para operá-las com segurança sem comprometer o isolamento de portas do servidor, aplique a tríade de proteção:

```
┌────────────────────────────────────────────────────────────────────────┐
│             TRÍADE DE PROTEÇÃO DE INTERFACES ADMINISTRATIVAS           │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Rota Mascarada: URL imprevisível (ex: /adm-nfe0e3n46d9g/)          │
│ 2. HTTP Basic Auth: O Nginx bloqueia antes mesmo do PHP ser executado │
│ 3. Restrição de IP: Apenas o IP do administrador pode requisitar a rota│
└────────────────────────────────────────────────────────────────────────┘
```

### 6.1 Implementação Completa no Nginx

#### 1. Gerar o arquivo de senhas do HTTP Basic Auth
```bash
sudo apt install apache2-utils -y
sudo htpasswd -c /etc/nginx/.htpasswd gestor_seguro
# Digite uma senha forte exclusiva para esta camada prévia
```

#### 2. Configurar o bloco de rota mascarada no Nginx
No arquivo do seu VirtualHost (ex: `/etc/nginx/sites-available/meusite.com`):

```nginx
server {
    listen 443 ssl http2;
    server_name meusite.com;

    # Certificados SSL gerenciados pelo Certbot / Let's Encrypt
    ssl_certificate /etc/letsencrypt/live/meusite.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/meusite.com/privkey.pem;

    # Aplicação principal
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # Rota Mascarada Secreta para Administração do Banco
    location /adm-nfe0e3n46d9g {
        alias /usr/share/phpmyadmin/;
        index index.php;

        # Camada 1: Autenticação Básica HTTP (Desafio no Nginx)
        auth_basic "Area Administrativa Restrita";
        auth_basic_user_file /etc/nginx/.htpasswd;

        # Camada 2: Restrição de IP (opcional, altamente recomendada)
        # allow 203.0.113.45; # Seu IP de casa/trabalho
        # deny all;

        location ~ ^/adm-nfe0e3n46d9g/(.+\.php)$ {
            alias /usr/share/phpmyadmin/$1;
            fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $request_filename;
        }

        location ~* ^/adm-nfe0e3n46d9g/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
            alias /usr/share/phpmyadmin/$1;
        }
    }
}
```

```bash
# Validar configuração e recarregar o Nginx
sudo nginx -t && sudo systemctl reload nginx
```

---

## 7. Camada 5: Detecção Ativa e Mitigação de Port Scans (Honeypots & Fail2Ban)

Além de manter as portas fechadas no firewall, uma VPS resiliente adota uma postura **ativa**: punir o atacante logo durante a fase preliminar de sondagem e reconhecimento.

### 7.1 Fail2Ban: Blindagem Contra Força Bruta

O **Fail2Ban** inspeciona os arquivos de log do sistema operacional em tempo real. Quando um endereço IP acumula sucessivos erros de autenticação ou tenta acessar rotas suspeitas, o Fail2Ban injeta uma regra dinâmica no firewall banindo aquele IP temporariamente ou permanentemente.

#### Instalação e Configuração:
```bash
sudo apt install fail2ban -y
```

Crie o arquivo de configuração local `/etc/fail2ban/jail.local`:
```ini
[DEFAULT]
# IP de casa/empresa que NUNCA deve ser banido (Whitelist)
ignoreip = 127.0.0.1/8 ::1 203.0.113.45

# Tempo de banimento (ex: 24 horas)
bantime = 24h

# Janela de tempo de observação
findtime = 10m

# Número máximo de falhas antes de aplicar o banimento
maxretry = 3

# Ação padrão: descartar pacotes (DROP) via UFW
banaction = ufw

# --- Jail Específica para SSH ---
[sshd]
enabled = true
port = 2244 # informe a porta real do seu SSH
logpath = %(sshd_log)s
backend = systemd

# --- Jail para Bloquear Scanners Web Maliciosos (Nginx 404/403) ---
[nginx-botsearch]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 2
```

Inicie e habilite o serviço:
```bash
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban
```

Comandos essenciais de gerenciamento:
```bash
# Verificar status das cadeias ativas
sudo fail2ban-client status

# Ver IPs banidos na cadeia do SSH
sudo fail2ban-client status sshd

# Desbanir manualmente um IP (ex: se alguém da equipe foi bloqueado por engano)
sudo fail2ban-client set sshd unbanip 198.51.100.12
```

---

### 7.2 Portsentry: O Honeypot Ativo de Portas

O **Portsentry** atua como um sistema de detecção de intrusão leve (HIDS). Ele cria "iscas" virtuais em portas que não possuem serviços reais em execução (como portas 23/Telnet, 111, 1024, etc.).

Quando um scanner de portas (como o Nmap) dispara pacotes contra uma dessas portas falsas para saber se o host está ativo, o Portsentry detecta o pacote imediatamente e aciona o firewall para bloquear o atacante de forma irrevogável.

```
┌────────────────────────────────────────────────────────────────────────┐
│                     COMO O PORTSENTRY FUNCIONA                         │
├────────────────────────────────────────────────────────────────────────┤
│  Scanner (Nmap) ──► Envia SYN para a Porta 23 (Telnet falsa / Isca)   │
│                             │                                          │
│                             ▼                                          │
│             Portsentry intercepta a conexão                            │
│                             │                                          │
│                             ▼                                          │
│  Executa comando: ufw insert 1 deny from <IP_ATACANTE> to any          │
│                             │                                          │
│                             ▼                                          │
│  O IP do atacante deixa de enxergar qualquer serviço na VPS!           │
└────────────────────────────────────────────────────────────────────────┘
```

#### Instalação e Ativação no Ubuntu/Debian:
```bash
sudo apt install portsentry -y
```

1. **Configurar a Whitelist Obrigatória:**
Adicione seu próprio IP no arquivo `/etc/portsentry/portsentry.ignore` para evitar o risco de se auto-bloquear acidentalmente.

2. **Configurar o Modo Avançado de Bloqueio:**
Edite `/etc/portsentry/portsentry.conf`:
```ini
# Ativar bloqueio automático para conexões TCP e UDP
BLOCK_UDP="1"
BLOCK_TCP="1"

# Comando disparado no momento da detecção do scan
KILL_ROUTE="/sbin/iptables -I INPUT -s $TARGET$ -j DROP"
```

3. **Definir o Modo de Operação:**
No arquivo `/etc/default/portsentry`, configure para o modo stealth avançado:
```ini
TCP_MODE="atcp"
UDP_MODE="audp"
```

Reinicie o serviço:
```bash
sudo systemctl restart portsentry
```

---

## 8. DROP vs REJECT: A Psicologia do Bloqueio de Rede

Ao configurar ferramentas de defesa e regras de firewall, você se deparará com duas ações fundamentais de bloqueio: **REJECT** e **DROP**.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        COMPORTAMENTO DE BLOQUEIO                       │
├────────────────────────────────────────────────────────────────────────┤
│ [REJECT]                                                               │
│ Atacante ──► SYN (Porta 3306) ──► Servidor responde com TCP RST        │
│ Efeito: O atacante sabe instantaneamente que o IP está ativo.          │
├────────────────────────────────────────────────────────────────────────┤
│ [DROP]                                                                 │
│ Atacante ──► SYN (Porta 3306) ──► Servidor ignora e descarta o pacote  │
│ Efeito: A conexão sofre Timeout (o scanner fica travado esperando).    │
└────────────────────────────────────────────────────────────────────────┘
```

| Critério | Ação REJECT | Ação DROP (Recomendada) |
| :--- | :--- | :--- |
| **Resposta ao Pacote** | Retorna um pacote de rejeição explícito (`TCP RST` ou `ICMP Port Unreachable`). | Descarta silenciosamente o pacote sem emitir nenhuma resposta pela rede. |
| **Visão do Atacante** | O atacante sabe em milissegundos que a porta está fechada, mas confirma que o servidor existe e está ligado. | O atacante não sabe se o IP existe, se está desligado ou se caiu na internet. |
| **Impacto em Scanners (Nmap)** | O scan de 65.535 portas roda em menos de 10 segundos. | O scan precisa aguardar o tempo de *timeout* em cada porta (2 a 3 segundos). Uma varredura completa passa a demorar mais de 30 horas! |
| **Consumo de Banda** | Consome banda de saída para responder a cada pacote do atacante. | Consumo zero de banda de saída; o kernel descarta o pacote na camada mais baixa possível. |

---

## 9. Auditoria e Verificação Prática: Como Testar Sua Própria VPS

Depois de implementar as regras, é obrigatório auditar a superfície de exposição para certificar-se de que nenhum serviço sensível ficou aberto por acidente.

### 9.1 Inspecionando Portas Abertas Dentro do Próprio Servidor
Utilize o utilitário moderno `ss` (substituto do obsoleto `netstat`):

```bash
sudo ss -tulpn
```

#### Como interpretar a saída:
* ✅ **Seguro:** `127.0.0.1:3306` ou `localhost:5432` — O serviço está ouvindo estritamente na interface de loopback interna.
* ❌ **PERIGOSO:** `0.0.0.0:3306` ou `:::3306` — O banco está aceitando conexões de qualquer placa de rede pública!
* ✅ **Esperado para Web:** `0.0.0.0:80` e `0.0.0.0:443` — Servidor Nginx/Apache público.

---

### 9.2 Realizando um Scan Externo com o Nmap
A partir do seu computador local (fora do servidor), execute um scan completo contra a VPS:

```bash
# Executado do seu terminal local:
nmap -sS -Pn -p- ip_da_sua_vps
```

#### O que você deve esperar como resultado ideal:
```text
PORT     STATE    SERVICE
80/tcp   open     http
443/tcp  open     https
2244/tcp open     custom-ssh
All other 65532 scanned ports on ip_da_vps are filtered (DROP)
```
Se qualquer porta como 3306, 5432, 6379 ou 8080 aparecer como `open`, volte imediatamente às etapas de configuração de loopback e firewall.

---

## 10. Checklist Definitivo de Hardening de Portas

Utilize este checklist como guia de auditoria antes de liberar qualquer servidor Linux para o tráfego de produção:

- [ ] **Política Padrão do Firewall:** O UFW está ativo com `default deny incoming` e `default allow outgoing`?
- [ ] **Loopback Liberado:** A interface local `lo` está liberada no UFW (`ufw allow in on lo`)?
- [ ] **Bancos de Dados Isolados:** MySQL, PostgreSQL e Redis estão escutando estritamente em `127.0.0.1`?
- [ ] **Acesso Remoto via Túnel SSH:** Conexões administrativas a bancos utilizam SSH Port Forwarding em vez de portas abertas?
- [ ] **Login por Senha Desativado no SSH:** A diretiva `PasswordAuthentication no` está em vigor no OpenSSH?
- [ ] **Login do Root Proibido:** A diretiva `PermitRootLogin no` está ativa e existe um usuário comum no grupo `sudo`?
- [ ] **Chaves Assimétricas:** O acesso administrativo é feito exclusivamente via chaves Ed25519 ou RSA 4096 bits?
- [ ] **Porta SSH Alternativa:** A porta padrão (22) foi alterada para mitigar o ruído de bots automatizados?
- [ ] **Fail2Ban em Operação:** As jails para SSH e servidores web estão monitorando logs e aplicando banimentos via DROP?
- [ ] **Whitelist Configurada:** Seu endereço IP residencial/corporativo está listado no `ignoreip` do Fail2Ban e no Portsentry para evitar auto-bloqueio?
- [ ] **Painéis Web Mascarados:** phpMyAdmin ou ferramentas equivalentes estão protegidos por rotas imprevisíveis e HTTP Basic Auth?
- [ ] **Auditoria Externa Concluída:** Um scan com `nmap -sS -Pn -p-` confirmou que apenas as portas essenciais (80, 443 e SSH) respondem externamente?
