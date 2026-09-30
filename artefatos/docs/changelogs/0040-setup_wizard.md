# Changelog - AgSonhos Setup Wizard (CL-0040)

* **Identificador:** CL-0040
* **Deploy Plan / Referência:** [DP-040 (Setup Wizard & Instalação Guiada)](file:///var/www/html/Guia_desenvolvimento_software/docs/architecture/deployment/deploy-plan_040.md)
* **Data da Conclusão:** 2026-09-30
* **Autor(es):** Equipe de Arquitetura e Engenharia de Software
* **Revisor(es):** Tech Lead de Backend & QA Lead
* **Status:** Concluído e Aprovado
* **Tipo de Alteração Predominante:** Added / Feature

---

## 1. Resumo Executivo

Esta fatia vertical entrega o **Setup Wizard (Assistente de Instalação Guiada)** para a plataforma AgSonhos, permitindo que a aplicação seja implantada e configurada em novos ambientes (desenvolvimento, staging ou instâncias de novos clientes) de forma 100% automatizada e visual, sem necessidade de manipulação manual de arquivos de configuração ou importações manuais de SQL via linha de comando.

A solução introduz o gerenciador atômico de configurações de ambiente ([`EnvironmentManager`](file:///var/www/html/Guia_desenvolvimento_software/backend/src/Infrastructure/Support/EnvironmentManager.php)), um middleware de interceptação global ([`InstallationCheckMiddleware`](file:///var/www/html/Guia_desenvolvimento_software/backend/src/Http/Middlewares/InstallationCheckMiddleware.php)) que redireciona acessos não instalados para o instalador e bloqueia tentativas indevidas após a finalização, além de testes AJAX de conectividade com MySQL, provisionamento completo de banco de dados e criação segura do usuário Super Administrador com criptografia Argon2id.

---

## 2. Impacto no Sistema e Quebras de Compatibilidade (*Breaking Changes*)

> [!IMPORTANT]
> **Atenção para Ambientes Existentes:**  
> A introdução do middleware de verificação de instalação intercepta todas as requisições HTTP da aplicação. Ambientes existentes **DEVEM** conter a chave `APP_INSTALLED=true` no arquivo `.env` para evitar o redirecionamento automático (302) para a rota `/setup`.

* **Retrocompatibilidade:** Preservada com a presença da chave `APP_INSTALLED=true` no `.env`.
* **Ações Requeridas no Deploy:**
  1. Garantir que os servidores com aplicação já em operação possuam `APP_INSTALLED=true` no `.env`.
  2. Para novas instalações, certificar-se de que o diretório `backend/` possua permissões de escrita para criação do `.env` (`0640`).

---

## 3. Alterações de Infraestrutura e Ambiente

### Variáveis de Ambiente (`.env`)
* `APP_INSTALLED`: Flag booleana (`true` / `false`) indicando o estado de prontidão do sistema. Adicionada a `backend/.env.example` com valor padrão `false`.

### Banco de Dados / Migrations
* Esquema SQL DDL canônico adicionado em [`backend/resources/schema/install.sql`](file:///var/www/html/Guia_desenvolvimento_software/backend/resources/schema/install.sql).
* Suporte a sementeira opcional de catálogo demonstrativo para homologação e CI (`Seed CI`).

### Permissões de Sistema de Arquivos
* O arquivo `.env` agora é gerado e atualizado de forma atômica (`.env.tmp` ➔ `rename`) com trava exclusiva (`LOCK_EX`) e permissões estritas `0640`.

---

## 4. Tarefas Concluídas e Arquivos Modificados

### 🚀 Added (Novas Funcionalidades e Componentes)

- [x] **Fase 1: Gerenciamento do Ambiente e Suporte (`EnvironmentManager`)**
  - Implementada classe [`App\Infrastructure\Support\EnvironmentManager`](file:///var/www/html/Guia_desenvolvimento_software/backend/src/Infrastructure/Support/EnvironmentManager.php).
  - Suporte a leitura inteligente de `.env` com fallback automático para `.env.example`.
  - Gravação atômica via arquivo temporário (`.env.tmp`), trava `LOCK_EX`, substituição via `rename` e aplicação de permissões seguras `0640`.
  - Suíte de testes unitários aprovada em [`tests/Unit/Infrastructure/Support/EnvironmentManagerTest.php`](file:///var/www/html/Guia_desenvolvimento_software/tests/Unit/Infrastructure/Support/EnvironmentManagerTest.php) (7 testes, 17 asserções).

- [x] **Fase 2: Middleware de Interceptação (`InstallationCheckMiddleware`)**
  - Criado [`App\Http\Middlewares\InstallationCheckMiddleware`](file:///var/www/html/Guia_desenvolvimento_software/backend/src/Http/Middlewares/InstallationCheckMiddleware.php).
  - Desvio automático 302 para a rota `/setup` quando o sistema estiver em estado `APP_INSTALLED=false`.
  - Bloqueio de segurança 403 Forbidden (respostas diferenciadas em JSON e HTML) para qualquer acesso a `/setup` quando `APP_INSTALLED=true`.
  - Suíte de testes unitários aprovada em [`tests/Unit/Http/Middlewares/InstallationCheckMiddlewareTest.php`](file:///var/www/html/Guia_desenvolvimento_software/tests/Unit/Http/Middlewares/InstallationCheckMiddlewareTest.php) (6 testes, 14 asserções).

- [x] **Fase 3: Controladores do Assistente de Instalação (`Setup Controllers`)**
  - Implementado [`App\Http\Controllers\Setup\ShowSetupAction`](file:///var/www/html/Guia_desenvolvimento_software/backend/src/Http/Controllers/Setup/ShowSetupAction.php) para diagnóstico de versão do PHP, extensões requeridas (PDO, OpenSSL, Mbstring) e permissões de escrita em disco.
  - Implementado [`App\Http\Controllers\Setup\TestDatabaseConnectionAction`](file:///var/www/html/Guia_desenvolvimento_software/backend/src/Http/Controllers/Setup/TestDatabaseConnectionAction.php) para validação assíncrona AJAX de credenciais do MySQL antes do provisionamento.
  - Implementado [`App\Http\Controllers\Setup\ProcessInstallationAction`](file:///var/www/html/Guia_desenvolvimento_software/backend/src/Http/Controllers/Setup/ProcessInstallationAction.php) com pipeline transacional completo: criação de schema, execução de DDL/Seeds, hashing seguro de senha do Super Admin com Argon2id e persistência atômica do `.env` com `APP_INSTALLED=true`.

- [x] **Fase 4: Roteamento e Injeção de Dependências**
  - Registrado arquivo de rotas isoladas em [`backend/config/routes/setup.php`](file:///var/www/html/Guia_desenvolvimento_software/backend/config/routes/setup.php).
  - Registrado middleware na esteira de requisição HTTP em [`public_html/index.php`](file:///var/www/html/Guia_desenvolvimento_software/public_html/index.php) e [`backend/config/middleware.php`](file:///var/www/html/Guia_desenvolvimento_software/backend/config/middleware.php).
  - Mapeadas as definições de serviço no container PHP-DI em [`backend/config/dependencies.php`](file:///var/www/html/Guia_desenvolvimento_software/backend/config/dependencies.php).
  - Atualizado template de ambiente [`backend/.env.example`](file:///var/www/html/Guia_desenvolvimento_software/backend/.env.example) com `APP_INSTALLED=false`.

- [x] **Fase 5: Interface Visual e Frontend do Setup Wizard**
  - Criada view moderna e responsiva em [`backend/resources/views/setup/installer.html.twig`](file:///var/www/html/Guia_desenvolvimento_software/backend/resources/views/setup/installer.html.twig).
  - Criado script desacoplado [`public_html/assets/js/setup/installer.js`](file:///var/www/html/Guia_desenvolvimento_software/public_html/assets/js/setup/installer.js) compatível com Content Security Policy (CSP nonce).
  - Suporte a seleção de perfil de carga de dados: "Instalação Limpa (Clean)" vs "Catálogo Completo de Demonstração (Seed CI)".
  - Importado esquema DDL canônico em [`backend/resources/schema/install.sql`](file:///var/www/html/Guia_desenvolvimento_software/backend/resources/schema/install.sql).

- [x] **Fase 6: Verificação Automatizada e Testes Ponta a Ponta**
  - Implementados testes de integração em [`tests/Integration/Setup/SetupWizardActionsTest.php`](file:///var/www/html/Guia_desenvolvimento_software/tests/Integration/Setup/SetupWizardActionsTest.php) (4 testes, 13 asserções).
  - Implementados testes de integração HTTP ponta a ponta com Slim 4 em [`tests/Integration/Http/InstallationCheckMiddlewareIntegrationTest.php`](file:///var/www/html/Guia_desenvolvimento_software/tests/Integration/Http/InstallationCheckMiddlewareIntegrationTest.php) (4 testes, 11 asserções).

---

## 5. Métricas de Qualidade e Evidências de Teste

| Escopo do Teste | Suíte / Arquivo | Quantidade de Testes | Asserções | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Unitário** | `EnvironmentManagerTest.php` | 7 | 17 | ✅ Aprovado |
| **Unitário** | `InstallationCheckMiddlewareTest.php` | 6 | 14 | ✅ Aprovado |
| **Integração** | `SetupWizardActionsTest.php` | 4 | 13 | ✅ Aprovado |
| **Integração** | `InstallationCheckMiddlewareIntegrationTest.php` | 4 | 11 | ✅ Aprovado |
| **Regressão Global** | Suíte Completa do Sistema (Unit + Integration) | **720** (378 unit + 342 integ) | **1.840** | ✅ 100% Pass |

---

## 6. Procedimento de Verificação e Rollback

### Verificação Pós-Deploy (*Smoke / Sanity Test*)
1. Em ambiente novo sem `.env`, acessar a URL raiz `/`: deve responder com redirecionamento HTTP 302 para `/setup`.
2. Completar os passos do assistente visual informando dados de banco de testes.
3. Confirmar que o arquivo `.env` foi gravado com `APP_INSTALLED=true` e permissões `0640`.
4. Tentar acessar `/setup` novamente: deve retornar erro HTTP 403 Forbidden.

### Procedimento de Rollback
1. Reverter o commit da fatia na branch de deploy.
2. Em caso de necessidade em ambiente prévio, garantir manualmente `APP_INSTALLED=true` no arquivo `.env` para desativar qualquer intervenção do instalador.