# 🏆 Divulgação Responsável: Implementando `security.txt` (RFC 9116) e Hall da Fama na VPS

> [!TIP]
> **Princípio Central:**
> Criar o arquivo padrão `/.well-known/security.txt` (**RFC 9116**) na raiz pública do seu site estabelece um canal oficial e padronizado para que pesquisadores de segurança reportem falhas de boa-fé antes que sejam exploradas, transformando potenciais invasores motivados por reconhecimento em aliados da sua segurança.

*(Veja o contexto estratégico por trás dessa prática em [boas-praticas-seguranca.md](./boas-praticas-seguranca.md).)*

---

## 📋 Índice

1. [Estrutura do Arquivo `security.txt` (RFC 9116)](#-1-estrutura-do-arquivo-securitytxt-rfc-9116)
2. [Publicando na VPS (Linux / Debian)](#-2-publicando-na-vps-linux--debian)
3. [Configuração no Servidor Web (Nginx, Apache, Caddy) e Cloudflare](#-3-configuração-no-servidor-web-nginx-apache-caddy-e-cloudflare)
4. [Assinatura Criptográfica com PGP (Opcional, Recomendado)](#-4-assinatura-criptográfica-com-pgp-opcional-recomendado)
5. [Criando a Página de Hall da Fama (`agradecimentos.html`)](#-5-criando-a-página-de-hall-da-fama-agradecimentoshtml)
6. [Validação e Testes Finais](#-6-validação-e-testes-finais)

---

## 📄 1. Estrutura do Arquivo `security.txt` (RFC 9116)

Crie um arquivo de texto puro (**UTF-8**, quebras de linha `\n`) adaptando os campos abaixo para o seu domínio:

```text
Contact: mailto:seguranca@seudominio.com.br
Expires: 2027-11-20T23:59:59.000Z
Encryption: https://seudominio.com.br/pgp-key.txt
Acknowledgments: https://seudominio.com.br/agradecimentos.html
Preferred-Languages: pt, en
Canonical: https://seudominio.com.br/.well-known/security.txt
Policy: https://seudominio.com.br/politica-divulgacao.html
```

### Significado dos campos principais

| Campo | Obrigatoriedade | Descrição |
| :--- | :--- | :--- |
| **`Contact`** | **Obrigatório** | Canal oficial de contato (`mailto:seguranca@...` ou `https://...` para formulário seguro). |
| **`Expires`** | **Obrigatório** | Data e hora de expiração no formato **ISO 8601** (UTC). Garante que o contato não fique obsoleto (renove anualmente). |
| **`Preferred-Languages`** | Recomendado | Idiomas aceitos para os relatos (ex.: `pt, en`). |
| **`Canonical`** | Recomendado | URL oficial do próprio arquivo `security.txt`, evitando falsificações ou cópias desatualizadas em espelhos. |
| **`Acknowledgments`** | Opcional | Link para a página de **Hall da Fama** com créditos aos pesquisadores que reportaram falhas de boa-fé. |
| **`Encryption`** | Opcional | URL para sua chave pública **PGP** (ou fingerprint), permitindo que o pesquisador envie detalhes sensíveis criptografados. |
| **`Policy`** | Opcional | Link para sua Política de Divulgação de Vulnerabilidades (**VDP**), definindo escopo permitido e regras (ex.: não testar DoS). |

---

## 🐧 2. Publicando na VPS (Linux / Debian)

Acesse o diretório raiz público do seu site na VPS (por exemplo, `/var/www/html` ou `/var/www/seudominio/public`) e execute:

```bash
# 1. Cria a pasta padrão .well-known
sudo mkdir -p /var/www/html/.well-known

# 2. Cria o arquivo security.txt (cole e adapte seu conteúdo)
sudo nano /var/www/html/.well-known/security.txt

# 3. Ajusta permissões de leitura para o servidor web (Nginx / Apache / Caddy)
sudo chmod 755 /var/www/html/.well-known
sudo chmod 644 /var/www/html/.well-known/security.txt
```

> [!NOTE]
> **Onde o arquivo deve ficar?**
> Segundo a **RFC 9116**, o caminho principal é `/.well-known/security.txt` (usando **HTTPS**). Evite depender apenas de `/security.txt` na raiz sem redirecionamento.

---

## 🌐 3. Configuração no Servidor Web (Nginx, Apache, Caddy) e Cloudflare

Muitos servidores web e regras de segurança bloqueiam por padrão diretórios iniciados por ponto (`.`) para proteger pastas sensíveis como `.git` ou `.env`. Garanta uma exceção explícita para `/.well-known/`:

### 3.1. Nginx

Dentro do bloco `server { ... }` do seu site (antes de regras genéricas de bloqueio de arquivos ocultos):

```nginx
location ^~ /.well-known/ {
    allow all;
    default_type text/plain;
}
```

Valide a sintaxe e recarregue o serviço:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

### 3.2. Apache (`.htaccess` ou `VirtualHost`)

Normalmente funciona por padrão, mas verifique se nenhuma regra global do tipo `RedirectMatch 403 /\..*` está bloqueando `.well-known`. Caso exista, ajuste o padrão negativo (*negative lookahead*) para liberar `.well-known`:

```apache
RedirectMatch 403 /\.(?!well-known).*
```

### 3.3. Caddy (`Caddyfile`)

O Caddy serve arquivos estáticos normalmente quando `file_server` está ativo. Se você bloqueia arquivos ocultos manualmente, adicione uma exceção para `/.well-known/*`:

```caddy
@hidden_blocked {
    path */.*
    not path /.well-known/*
}
respond @hidden_blocked 403
```

### 3.4. Atenção à Borda (Cloudflare WAF)

Se você utiliza regras no Cloudflare WAF ou no Nginx para bloquear varreduras em arquivos ocultos (como descrito em [saved-traffic-cost.md](../saved-traffic-cost.md)), certifique-se de bloquear prefixos específicos (`/.env`, `/.git`) e **não** bloquear todo caminho contendo `/.`, para não impedir o acesso público a `/.well-known/security.txt`.

---

## 🔐 4. Assinatura Criptográfica com PGP (Opcional, Recomendado)

Assinar o `security.txt` com **PGP** (*clearsign*) comprova que o arquivo não foi adulterado caso alguém comprometa parte do servidor ou faça *spoofing*:

```bash
# 1. Gere um par de chaves PGP dedicado para segurança (caso ainda não tenha)
gpg --full-generate-key

# 2. Exporte a chave pública para publicar no caminho definido em Encryption:
gpg --armor --export seguranca@seudominio.com.br | sudo tee /var/www/html/pgp-key.txt > /dev/null

# 3. Assine o arquivo security.txt em formato clearsign (substituindo o arquivo final)
gpg --clearsign --armor -o /tmp/security.txt.signed /var/www/html/.well-known/security.txt
sudo mv /tmp/security.txt.signed /var/www/html/.well-known/security.txt
sudo chmod 644 /var/www/html/.well-known/security.txt
```

O resultado terá blocos `-----BEGIN PGP SIGNED MESSAGE-----` e `-----BEGIN PGP SIGNATURE-----` envolvendo os campos RFC 9116, perfeitamente legível por navegadores e validadores.

---

## 🏅 5. Criando a Página de Hall da Fama (`agradecimentos.html`)

Se você preencheu o campo `Acknowledgments`, crie uma página simples e estática listando os pesquisadores autorizados, a data e um resumo genérico (sem expor detalhes exploráveis da vulnerabilidade):

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <title>Hall da Fama de Segurança</title>
</head>
<body>
  <h1>Hall da Fama de Segurança</h1>
  <p>Agradecemos aos pesquisadores que reportaram vulnerabilidades de forma responsável:</p>
  <ul>
    <li><strong>2026-11</strong> Nome ou Pseudônimo do Pesquisador (Correção de validação de cabeçalhos)</li>
  </ul>
</body>
</html>
```

---

## ✅ 6. Validação e Testes Finais

1. **Teste via linha de comando (`curl`):**
   ```bash
   curl -i https://seudominio.com.br/.well-known/security.txt
   ```
   Confirme retorno **`HTTP/2 200`** (ou `200 OK`) e `Content-Type: text/plain`.
2. **Teste no navegador:** Acesse `https://seudominio.com.br/.well-known/security.txt` e confira se o texto puro é exibido sem erros `403` ou `404`.
3. **Validador oficial da comunidade:** Cole seu domínio ou conteúdo em [securitytxt.org](https://securitytxt.org/) para validar sintaxe, campos obrigatórios e data `Expires`.
