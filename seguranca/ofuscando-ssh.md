# 🔐 Ofuscação e Hardening de SSH na VPS (Debian 13 — Skanstull)

> [!IMPORTANT]
> **A ofuscação de porta deve ser uma das últimas camadas de segurança, nunca a primeira.**
> A melhor prática de mercado atual não é esconder o SSH na porta `443`, mas sim **autenticar exclusivamente por chaves (`Ed25519`)** e, sempre que possível, **fechar a porta SSH para a internet pública** utilizando uma VPN (*Tailscale* ou *WireGuard*) ou túnel (*Cloudflare Tunnel*).
> Trocar a porta `22` por uma porta alta reduz em ~99% o ruído de bots e *scanners* genéricos nos logs, enquanto embutir na `443` via proxy reverso (`SSLH`/Nginx) adiciona complexidade desnecessária e dificulta o rastreio de IPs no Fail2Ban.

---

## 1. Comparação das Abordagens

| Abordagem | Segurança Real | Praticidade | Veredito de Mercado |
| :--- | :--- | :--- | :--- |
| **VPN / Túnel** (*Tailscale, WireGuard, Cloudflare Tunnel*) | **Altíssima** (porta SSH 100% fechada no firewall público) | Alta | **Padrão ouro** atual para servidores em nuvem e VPS. |
| **Chave Ed25519 + Fail2Ban** (na porta `22` ou porta alta) | **Alta** (imune a força bruta de senha) | Alta | Mínimo obrigatório caso o SSH precise ficar exposto à internet. |
| **Trocar a porta `22`** (ex.: `2244` ou `> 10000`) | **Baixa isoladamente** (*security by obscurity*; scanners encontram rápido) | Média | Útil para limpar logs e economizar CPU, desde que já haja hardening por chave. |
| **Embutir na porta `443`** (via `SSLH` / Nginx) | **Média** (ainda exposto, exige proxy extra e complica o Fail2Ban) | Baixa | Recomendado apenas se você acessa de redes corporativas que bloqueiam outras portas. |

---

## 2. Pré-Requisitos Obrigatórios (Antes de Mudar a Porta)

Antes de pensar em trocar a porta `22`, garanta que a segurança real já está aplicada na VPS (**Debian 13 / Hostinger**):

1. **Usuário administrativo dedicado (`deploy`):** Evite uso diário de `root`.
2. **Bloqueio total de senha via prefixo `00-`:**
   No Debian 13, o arquivo `/etc/ssh/sshd_config.d/50-cloud-init.conf` frequentemente define `PasswordAuthentication yes`. Como o OpenSSH aplica a regra *first-match-wins* em ordem alfabética, crie `/etc/ssh/sshd_config.d/00-hardening.conf` para ter prioridade absoluta:
   ```ini
   PubkeyAuthentication yes
   PasswordAuthentication no
   KbdInteractiveAuthentication no
   PermitRootLogin no
   ```
3. **Fail2Ban ativo com `backend = systemd`:** Configure a jail `[sshd]` em `/etc/fail2ban/jail.local` lendo diretamente do `journald` para banir IPs abusivos no UFW automaticamente.
4. **Opção VPN (opcional, máxima segurança):** Se utilizar *Tailscale* ou *WireGuard*, basta liberar o SSH apenas na interface da VPN e remover a regra pública:
   ```bash
   sudo ufw allow in on tailscale0 to any port 22 proto tcp
   sudo ufw delete allow 22/tcp
   ```

---

## 3. Passo a Passo Seguro para Trocar a Porta SSH

Se o SSH precisar continuar acessível pela internet pública (ex.: para administração direta, túneis SSH para MySQL `3306`/MongoDB `27017` ou `git push` no Forgejo) e você quiser reduzir o ruído de scanners trocando a porta `22` por uma porta alta (ex.: `2244` ou `54321`), siga **exatamente esta ordem** para evitar *lockout*:

### Passo 1 — Liberar a nova porta no UFW (mantendo a `22` aberta)

```bash
sudo ufw allow 2244/tcp comment 'SSH Customizado'
sudo ufw status verbose
```

### Passo 2 — Configurar a nova porta em `/etc/ssh/sshd_config.d/00-hardening.conf`

Adicione a diretiva `Port` ao arquivo de hardening (mantendo as travas de senha e `root`):

```ini
Port 2244
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
```

Valide a sintaxe antes de aplicar:

```bash
sudo sshd -t
```

### Passo 3 — Atualizar o Fail2Ban (`/etc/fail2ban/jail.local`)

Garanta que o Fail2Ban passe a monitorar e bloquear a nova porta na seção `[sshd]`:

```ini
[sshd]
enabled  = true
backend  = systemd
port     = 2244
maxretry = 5
bantime  = 1h
```

### Passo 4 — Reiniciar SSH (e `ssh.socket`) + Fail2Ban

> [!NOTE]
> Em sistemas modernos como **Debian 13** e **Ubuntu 22.10+**, o daemon pode usar *socket activation* (`ssh.socket`). Se apenas reiniciar `ssh.service` mantiver a porta `22`, reinicie o `ssh.socket` também.

```bash
sudo systemctl daemon-reload
sudo systemctl restart ssh.socket ssh.service
sudo systemctl restart fail2ban
```

Confirme em qual porta o servidor está escutando:

```bash
sudo ss -tlnp | grep sshd
sudo sshd -T | grep -iE 'port|passwordauthentication|permitrootlogin'
```

### Passo 5 — Testar em um SEGUNDO terminal (sem fechar o atual!)

Abra **outra janela de terminal** na sua máquina local e valide o acesso com o usuário `deploy`:

```bash
ssh -p 2244 deploy@IP_DA_VPS
```

*(Caso ocorra qualquer imprevisto e você perca o acesso, utilize o **Browser Terminal** no hPanel da Hostinger como console de emergência).*

### Passo 6 — Fechar a porta `22` no firewall

Somente após confirmar que a conexão pela porta `2244` funcionou perfeitamente, remova a regra antiga:

```bash
sudo ufw delete allow 22/tcp
sudo ufw status verbose
```

---

## 4. Ajustes no Cliente Local e Serviços do Skanstull

Ao alterar a porta padrão `22` na VPS, atualize também os pontos que dependem dela:

### 4.1. Atalho Local (`~/.ssh/config`)

Atualize o bloco do seu computador local para não precisar digitar `-p 2244` em conexões, `scp`, `rsync` ou túneis SSH (`3306`, `27017`, `9090`):

```sshconfig
Host skanstull-vps
    HostName IP_DA_VPS
    User deploy
    Port 2244
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### 4.2. Impacto no Forgejo (`git push` / `git pull` via SSH)

Como o Forgejo utiliza o usuário `git` do próprio sistema operacional via daemon OpenSSH:

1. **URL do Remote Git:** Passe a incluir a nova porta no formato `ssh://`:
   ```bash
   git remote set-url origin ssh://git@agsonhos.com.br:2244/usuario/Rust-e-commerce-Alpha.git
   ```
2. **Configuração do Forgejo (`/etc/forgejo/app.ini`):** Na seção `[server]`, ajuste `SSH_PORT = 2244` para que a interface web do Forgejo exiba a URL de clone SSH com a porta correta (e reinicie `sudo systemctl restart forgejo`).

---

## 5. Documentos Relacionados no Projeto

* [Guia de Conexão e Hardening SSH (`connect-vsp-via-ssh.md`)](../../Rust-e-commerce-Alpha/connect-vsp-via-ssh.md)
* [FIX-006: Precedência `00-hardening.conf` vs `50-cloud-init.conf`](../../Rust-e-commerce-Alpha/docs/issues/fix-006-check-ssh.md)
* [Topologia de Rede e Segurança Perimetral](../../Rust-e-commerce-Alpha/docs/architecture/network-topology/README.md)
