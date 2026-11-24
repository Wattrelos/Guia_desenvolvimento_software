# Como se Conectar ao Servidor VPS via SSH (Hostinger + Debian 13)

Este guia apresenta o passo a passo completo para localizar o endereço IP do seu servidor VPS na Hostinger, configurar a autenticação segura por chaves SSH (`Ed25519`), criar atalhos de acesso no seu computador local e aplicar boas práticas de segurança (*hardening*) no **Debian 13**.

---

## 📋 Sumário

1. [Descobrir o endereço IP do VPS](#1-descobrir-o-endereço-ip-do-vps)
2. [Gerar o par de chaves SSH no seu computador](#2-gerar-o-par-de-chaves-ssh-no-seu-computador)
3. [Adicionar a chave pública ao VPS](#3-adicionar-a-chave-pública-ao-vps)
4. [Conectar ao VPS via SSH](#4-conectar-ao-vps-via-ssh)
5. [Criar um atalho de conexão (`~/.ssh/config`)](#5-criar-um-atalho-de-conexão-sshconfig)
6. [Boas práticas de segurança (*Hardening* no Debian 13)](#6-boas-práticas-de-segurança-hardening-no-debian-13)
7. [Comandos úteis no dia a dia (túneis e transferência de arquivos)](#7-comandos-úteis-no-dia-a-dia-túneis-e-transferência-de-arquivos)
8. [Solução de problemas comuns (*Troubleshooting*)](#8-solução-de-problemas-comuns-troubleshooting)

---

## 1. Descobrir o endereço IP do VPS

Você pode obter o IPv4 público do servidor pelo painel da Hostinger (**hPanel**) ou diretamente pelo terminal do navegador.

### Opção A: Pelo painel da Hostinger (hPanel)

Esta é a forma mais rápida caso você ainda não tenha conectado ao servidor:

1. Entre na sua conta no **hPanel** e clique em **VPS** no menu superior.
2. Clique no botão **Gerenciar** ao lado do seu servidor Debian 13.
3. Na página de **Visão Geral**, o **Endereço IP (IPv4)** aparece no topo da tela, junto aos detalhes de acesso SSH. Clique no ícone de copiar ao lado dele.

### Opção B: Pelo terminal do próprio VPS (*Browser Terminal*)

Se você já estiver usando o terminal do navegador dentro do painel da Hostinger, execute um dos comandos abaixo:

* **Consultar o IPv4 público via requisição externa:**

  ```bash
  curl -4 ifconfig.me
  ```

* **Listar os endereços IPv4 das interfaces de rede:**

  ```bash
  ip -4 addr show
  ```

  > Procure pelo endereço logo após `inet` na sua interface principal (geralmente `eth0` ou `ens3`).

---

## 2. Gerar o par de chaves SSH no seu computador

Em vez de depender apenas de senha, o ideal é autenticar usando um par de chaves criptográficas: uma **chave privada** (que nunca sai do seu computador) e uma **chave pública** (que será copiada para o servidor).

Abra o terminal do seu sistema operacional (**Terminal** no Linux/macOS ou **PowerShell** no Windows) e execute:

```bash
ssh-keygen -t ed25519 -C "meu-pc-debian13"
```

> [!NOTE]
> O algoritmo `Ed25519` é o padrão moderno recomendado por ser mais rápido e seguro. Caso utilize um sistema muito antigo sem suporte a `Ed25519`, use RSA de 4096 bits:
>
> ```bash
> ssh-keygen -t rsa -b 4096 -C "meu-pc-debian13"
> ```

Durante a execução, o comando fará duas perguntas:

1. **Local para salvar a chave:** pressione `Enter` para aceitar o padrão (`~/.ssh/id_ed25519`).
2. **Frase-senha (*passphrase*):** digite uma senha para proteger a chave privada em disco (recomendado) ou pressione `Enter` duas vezes para deixá-la sem senha.

> [!TIP]
> Se você definiu uma *passphrase* no Debian 13 local e não quiser digitá-la a cada conexão, adicione a chave ao agente SSH da sua sessão:
>
> ```bash
> eval "$(ssh-agent -s)"
> ssh-add ~/.ssh/id_ed25519
> ```

---

## 3. Adicionar a chave pública ao VPS

Primeiro, visualize e copie o conteúdo da sua **chave pública** (`.pub`):

* **Linux / macOS:**

  ```bash
  cat ~/.ssh/id_ed25519.pub
  ```

* **Windows (PowerShell):**

  ```powershell
  type $env:USERPROFILE\.ssh\id_ed25519.pub
  ```

Copie a linha inteira exibida no terminal (ela começa com `ssh-ed25519 AAAA...`).

### Método A: Pelo painel da Hostinger (ideal para VPS recém-criado)

1. No **hPanel**, acesse **VPS** ➔ **Gerenciar**.
2. No menu lateral esquerdo, vá em **Configurações** ➔ **Chaves SSH** (ou na seção **Acesso SSH** da visão geral).
3. Clique em adicionar nova chave, dê um nome identificador (ex.: `notebook-debian13`) e cole o conteúdo da sua chave pública.

> [!IMPORTANT]
> Em alguns VPS que já estão em execução há mais tempo, adicionar a chave pelo hPanel pode exigir reinicialização ou aplicar-se apenas em reinstalações do sistema. Nesse caso, utilize o **Método B** abaixo.

### Método B: Diretamente no servidor (VPS já em execução)

Se o acesso por senha ainda estiver ativo no VPS, você pode enviar a chave automaticamente a partir do seu Linux/macOS com um único comando:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@SEU_IP_DO_VPS
```

Caso esteja no Windows ou usando o *Browser Terminal* da Hostinger, conecte-se ao servidor e execute os comandos abaixo dentro do VPS para registrar a chave manualmente com as permissões corretas:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "COLE_SUA_CHAVE_PUBLICA_AQUI" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

> [!WARNING]
> O servidor SSH recusa a autenticação por chave se as permissões estiverem muito abertas. Garanta sempre `700` para `~/.ssh` e `600` para `~/.ssh/authorized_keys`.

---

## 4. Conectar ao VPS via SSH

No terminal do seu computador local, execute (substituindo `SEU_IP_DO_VPS` pelo IPv4 real):

```bash
ssh root@SEU_IP_DO_VPS
```

* **Primeira conexão:** o terminal perguntará se você confia na autenticidade do servidor (`Are you sure you want to continue connecting (yes/no/[fingerprint])?`). Digite `yes` e pressione `Enter`.
* **Autenticação:** se você criou uma *passphrase* para a chave no Passo 2, digite-a para liberar o acesso.

---

## 5. Criar um atalho de conexão (`~/.ssh/config`)

Para não precisar digitar o IP, usuário e caminho da chave toda vez que for acessar o servidor, configure um alias no arquivo `~/.ssh/config` do seu computador local.

1. Abra (ou crie) o arquivo de configuração:

   ```bash
   nano ~/.ssh/config
   ```

2. Adicione o bloco abaixo substituindo pelos seus dados:

   ```sshconfig
   Host meu-vps
       HostName SEU_IP_DO_VPS
       User root
       Port 22
       IdentityFile ~/.ssh/id_ed25519
       IdentitiesOnly yes
       ServerAliveInterval 60
       ServerAliveCountMax 3
   ```

   * `IdentitiesOnly yes`: evita que o cliente tente todas as chaves locais antes da correta.
   * `ServerAliveInterval 60`: envia um sinal a cada 60 segundos para evitar que a conexão caia por inatividade.

3. Salve no `nano` (`Ctrl + O`, `Enter`, `Ctrl + X`) e ajuste a permissão do arquivo (obrigatório no Linux):

   ```bash
   chmod 600 ~/.ssh/config
   ```

4. A partir de agora, basta rodar:

   ```bash
   ssh meu-vps
   ```

---

## 6. Boas práticas de segurança (*Hardening* no Debian 13)

Depois de confirmar que o login por chave SSH funciona perfeitamente, recomenda-se blindar o servidor contra ataques de força bruta.

### 6.1. Criar um usuário comum com `sudo` (evitar uso diário de `root`)

Dentro do VPS, crie um usuário administrativo (ex.: `deploy`) e copie sua chave SSH para ele:

```bash
adduser deploy
usermod -aG sudo deploy
rsync --archive --chown=deploy:deploy ~/.ssh /home/deploy
```

> Antes de prosseguir, abra **outro terminal** no seu computador e teste `ssh deploy@SEU_IP_DO_VPS` + `sudo whoami` para confirmar que o novo usuário entra com chave e possui privilégios `sudo`.

### 6.2. Desativar login por senha e restringir o `root`

No Debian 13, a forma mais limpa de configurar o `sshd` sem conflitar com atualizações do pacote é criar um arquivo em `/etc/ssh/sshd_config.d/`:

```bash
sudo nano /etc/ssh/sshd_config.d/99-hardening.conf
```

Conteúdo recomendado:

```ini
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
```

> [!CAUTION]
> **Nunca feche sua sessão SSH atual antes de testar a nova configuração!**
>
> 1. Valide a sintaxe e verifique as diretivas efetivas:
>
>    ```bash
>    sudo sshd -t
>    sudo sshd -T | grep -iE 'passwordauthentication|permitrootlogin|pubkeyauthentication'
>    ```
>
> 2. Recarregue o serviço SSH no Debian 13:
>
>    ```bash
>    sudo systemctl reload ssh
>    ```
>
> 3. Em uma **nova janela do terminal**, teste o acesso com `ssh deploy@SEU_IP_DO_VPS`. Só encerre a sessão antiga após confirmar que o novo login funcionou.
> 4. Se estiver usando o atalho do Passo 5, atualize `User root` para `User deploy` no seu `~/.ssh/config` local.

> [!NOTE]
> Se desejar também alterar a porta padrão `22` (ex.: para `2222`), adicione `Port 2222` no arquivo `99-hardening.conf`, libere a nova porta no firewall **antes** de recarregar o SSH e atualize o campo `Port` no seu `~/.ssh/config` local.

### 6.3. Ativar firewall básico (`ufw`) e proteção contra força bruta (`fail2ban`)

```bash
sudo apt update && sudo apt install -y ufw fail2ban
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw enable
sudo ufw status verbose
```

---

## 7. Comandos úteis no dia a dia (túneis e transferência de arquivos)

Com o atalho `meu-vps` configurado no `~/.ssh/config`, você pode usar o mesmo alias em outras ferramentas:

* **Enviar um arquivo local para o VPS (`scp`):**

  ```bash
  scp ./arquivo.tar.gz meu-vps:/tmp/
  ```

* **Sincronizar uma pasta local com o servidor (`rsync`):**

  ```bash
  rsync -avz --progress ./dist/ meu-vps:/var/www/app/
  ```

* **Criar um túnel SSH seguro (Port Forwarding):**
  Ideal para acessar serviços internos do servidor (como painéis de monitoramento ou bancos de dados na porta `3000` ou `3306` ligados a `127.0.0.1`) sem expor essas portas na internet:

  ```bash
  ssh -L 3000:127.0.0.1:3000 -N meu-vps
  ```

  Enquanto o comando estiver aberto, acesse `http://127.0.0.1:3000` no navegador do seu computador como se estivesse local.

---

## 8. Solução de problemas comuns (*Troubleshooting*)

| Sintoma / Mensagem de Erro | Causa Provável | Como Resolver |
| :--- | :--- | :--- |
| `Permission denied (publickey)` | Chave pública não está em `~/.ssh/authorized_keys`, usuário errado ou permissões incorretas | Verifique se está usando o usuário certo (`root` vs `deploy`). No servidor, garanta `chmod 700 ~/.ssh` e `chmod 600 ~/.ssh/authorized_keys`. Rode `ssh -vvv meu-vps` no cliente para diagnosticar. |
| `Bad owner or permissions on ~/.ssh/config` | Arquivo `~/.ssh/config` local com permissão de escrita para grupo/outros | Execute `chmod 600 ~/.ssh/config` no seu computador local. |
| `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` | O VPS foi reinstalado ou o IP mudou de máquina | Remova a assinatura antiga do servidor conhecido com `ssh-keygen -R SEU_IP_DO_VPS` e reconecte. |
| `Connection refused` | Serviço SSH parado ou porta incorreta | Confira a porta configurada (`-p PORTA`) e, pelo *Browser Terminal* da Hostinger, cheque `sudo systemctl status ssh`. |
| `Connection timed out` | IP incorreto ou firewall bloqueando a porta SSH | Confirme o IPv4 no hPanel e verifique as regras do firewall (`sudo ufw status`) ou do painel da Hostinger. |
