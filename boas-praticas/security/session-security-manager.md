# Prevenção contra roubo de sessão.
Para evitar que as sessões dos usuários fiquem ativas por tempo indeterminado e dependam exclusivamente do timeout de inatividade (como os 30 minutos citados), você deve implementar uma estratégia de Absolute Session Timeout (Tempo Limite Absoluto) combinada com o gerenciamento dinâmico de tokens.
Aqui estão as melhores práticas para resolver esse problema:
## 1. Implementar o Tempo Limite Absoluto (Absolute Timeout)
Independentemente de quão ativo o usuário esteja, a sessão deve obrigatoriamente expirar após um período fixo (por exemplo, 8 horas, 12 horas ou 24 horas).

* Quando esse limite é atingido, o servidor destrói a sessão e força um novo login.
* Isso limita a janela de oportunidade de um atacante caso um token ou cookie seja roubado.

## 2. Utilizar a o cnEstratégia de Access e Refresh Tokens (OAuth2 / JWT)
Se a sua aplicação utiliza tokens (como JWT) em vez de sessões tradicionais no servidor, divida a autenticação em duas partes:

* Access Token (Curto): Tem um tempo de vida muito curto (ex: 5 a 15 minutos). É usado para autenticar cada requisição nas APIs.
* Refresh Token (Longo + Rotação): Tem um tempo de vida maior (ex: 7 dias) e é guardado em um cookie HttpOnly e Secure. Ele serve apenas para pedir um novo Access Token quando o antigo expirar.

## O segredo: Rotação de Refresh Tokens (Token Rotation)
Para evitar que o Refresh Token torne a sessão eterna ou perigosa:

   1. Sempre que o cliente usar o Refresh Token para pedir um novo Access Token, o servidor invalida o Refresh Token antigo e envia um novo Refresh Token de volta.
   2. Se um atacante roubar um Refresh Token e tentar usá-lo, o servidor detectará o reuso (já que o usuário legítimo também tentará usar o mesmo token em algum momento). O servidor deve então invalidar imediatamente toda a família de tokens daquele usuário, forçando o logout global por segurança.

## 3. Implementar a Expiração no Lado do Cliente (Dê o aviso)
Para melhorar a experiência do usuário e garantir que o navegador limpe os dados locais:

* Crie um timer em JavaScript que acompanha o tempo de inatividade.
* Faltando 2 minutos para expirar (ex: aos 28 minutos de inatividade), exiba um alerta: "Sua sessão está prestes a expirar. Deseja continuar conectado?".
* Se o usuário não responder, o JavaScript faz uma chamada para a rota de /logout do back-end para destruir a sessão no servidor e limpa o armazenamento local (localStorage ou cookies de sessão do cliente).

## Comparação das Abordagens

| Estratégia | Como funciona | O que resolve |
|---|---|---|
| Idle Timeout (Inatividade) | Expira se o usuário não clicar em nada por X minutos. | Protege o computador que foi deixado aberto fisicamente. |
| Absolute Timeout (Absoluto) | Expira obrigatoriamente após X horas, mesmo com o usuário ativo. | Limpa sessões esquecidas em navegadores e limita o tempo de posse de um token roubado. |
| Refresh Token Rotation | Renova as chaves de acesso a cada poucos minutos de forma transparente. | Evita sessões eternas e detecta roubos de credenciais de API de forma automatizada. |

# Lista das principais implementações de segurança

Para construir uma aplicação verdadeiramente segura, além de gerenciar o ciclo de vida das sessões, o desenvolvedor deve adotar uma abordagem de segurança em camadas (Defense in Depth).
Abaixo estão as práticas essenciais divididas por áreas críticas:

## 1. Fortalecimento de Cookies e Armazenamento
Os tokens e identificadores de sessão são os alvos principais dos atacantes. Se você os armazena no navegador, configure-os com o máximo de restrições:

*
* HttpOnly: Impede o acesso aos cookies via JavaScript, anulando o roubo de sessão por ataques de Cross-Site Scripting (XSS).
* Secure: Obriga o navegador a enviar o cookie apenas sob conexões criptografadas (HTTPS).
* SameSite=Lax ou Strict: Restringe o envio de cookies em requisições vindas de outros sites, mitigando ataques de CSRF.
* Evite localStorage para segredos: Dados guardados no localStorage ou sessionStorage ficam expostos a qualquer script rodando na página. Prefira cookies com as flags acima.
*

## 2. Proteção contra Injeção de Código (XSS e SQLi)
Se um atacante conseguir injetar scripts ou comandos no seu site, ele poderá burlar as defesas de sessão.

*
* Higienização e Escapamento (Output Encoding): Nunca confie em dados inseridos pelo usuário. Sempre escape a saída antes de renderizá-la no HTML para evitar o XSS.
* Content Security Policy (CSP): Implemente um cabeçalho HTTP de CSP robusto. Ele dita quais origens podem carregar scripts, imagens e conexões no seu site, bloqueando a execução de códigos maliciosos injetados.
* Consultas Parametrizadas (Prepared Statements): Use ORMs ou queries parametrizadas para barrar o SQL Injection (SQLi) no banco de dados.
*

## 3. Cabeçalhos de Segurança HTTP (Security Headers)
Configure o servidor web para enviar cabeçalhos que ativam defesas nativas nos navegadores dos usuários:

*
* Strict-Transport-Security (HSTS): Força o navegador a se comunicar com seu site estritamente via HTTPS, prevenindo interceptações.
* X-Content-Type-Options: nosniff: Impede que o navegador tente adivinhar o tipo de arquivo (MIME type), evitando a execução de scripts disfarçados de imagens.
* X-Frame-Options: DENY ou SAMEORIGIN: Protege seu site contra Clickjacking (quando o seu site é renderizado de forma invisível dentro de outro site para enganar os cliques do usuário).
*

## 4. Autenticação e Controle de Acesso Rígidos

*
* Múltiplo Fator de Autenticação (MFA): Implemente a exigência de uma segunda camada de validação (como aplicativos de autenticação) para ações sensíveis e logins.
* Políticas de Senha Fortes e Hashing: Force senhas complexas e nunca guarde senhas em texto limpo. Use algoritmos modernos de hash como Argon2 ou Bcrypt.
* Princípio do Menor Privilégio: Usuários e APIs devem ter acesso apenas ao estritamente necessário para exercer suas funções (RBAC - Controle de Acesso Baseado em Funções).
*

## 5. Monitoramento e Resiliência (Defesa Ativa)

*
* Rate Limiting (Limitador de Requisições): Bloqueie ou limite o número de requisições por IP ou por conta em endpoints críticos (como a tela de login) para evitar ataques de força bruta e negação de serviço (DoS).
* Log de Auditoria Centralizado: Registre eventos críticos (falhas de login, alteração de privilégios, troca de senha) sem expor dados sensíveis do usuário (como a própria senha ou tokens de sessão).
*

## Resumo das Práticas Básicas

[ Usuário ] ──( HTTPS / HSTS )──> [ Navegador (CSP + Cookies HttpOnly) ]
                                          │
                                ( Rate Limiting )
                                          ▼
                                [ Código Limpo (Evitar XSS/SQLi) ]
                                          │
                                          ▼
                                [ Banco de Dados (Hashes Fortes) ]

