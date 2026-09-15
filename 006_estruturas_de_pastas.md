# Guia Definitivo de Estrutura de Pastas e Padrões Arquiteturais
### *Do PHP Moderno (PSR-4) ao Java (Spring Boot), Clean Architecture, Hexagonal e DDD*

> 📌 **Nota do Autor:**  
> Este documento é um guia referencial de boas práticas de engenharia de software, reunindo os padrões mais consolidados e recomendados pela comunidade global de desenvolvimento. Ele serve como bússola de aprendizado para transformar o hábito de "apenas sair programando" em uma mentalidade estruturada de design de software profissional.

---

## 🧭 Sumário
1. [Por Onde Começar? Quebrando os 5 Vícios Mais Comuns](#1-por-onde-começar-quebrando-os-5-vícios-mais-comuns)
2. [O Padrão Moderno no Ecossistema PHP (PSR-4 / Composer)](#2-o-padrão-moderno-no-ecossistema-php-psr-4--composer)
3. [Como a PSR-4 Funciona Sob o Capô (e o Perigo do Linux)](#3-como-a-psr-4-funciona-sob-o-capô-e-o-perigo-do-linux)
4. [A Mesma Filosofia no Mundo Java (Spring Boot / Maven)](#4-a-mesma-filosofia-no-mundo-java-spring-boot--maven)
5. [Tabela de Equivalência: PHP vs Java](#5-tabela-de-equivalência-php-vs-java)
6. [Clean Architecture, Arquitetura Hexagonal e DDD na Prática](#6-clean-architecture-arquitetura-hexagonal-e-ddd-na-prática)
7. [Anatomia de um Fluxo Real: Do Request HTTP ao Banco de Dados](#7-anatomia-de-um-fluxo-real-do-request-http-ao-banco-de-dados)
8. [A Regra de Ouro das 3 Perguntas Antes de Criar um Arquivo](#8-a-regra-de-ouro-das-3-perguntas-antes-de-criar-um-arquivo)

---

## 1. Por Onde Começar? Quebrando os 5 Vícios Mais Comuns

Quando começamos a programar, nosso cérebro foca 100% em **fazer funcionar**. Criamos arquivos soltos, funções gigantescas e misturamos HTML, SQL e regras de negócio no mesmo lugar. O problema é que o software cresce, e aquilo que parecia simples se torna um pesadelo de manutenção.

Eis os 5 vícios mais comuns que distinguem o código amador do profissional:

```
❌ VÍCIO AMADOR                                  ✅ BOA PRÁTICA PROFISSIONAL
───────────────────────────────────────────────────────────────────────────────────────
1. Pastas "Lixão" (utils/, helpers/, classes/)   ➔ Separação por Responsabilidade (Domain, Infra)
2. SQL e Regras dentro do Controller             ➔ Controllers "Magros" (Skinny Controllers)
3. Expor a raiz do projeto no Apache/Nginx       ➔ Raiz pública estritamente isolada (public/)
4. Mistura de cases (snake_case com camelCase)   ➔ Rigidez PSR-4 / PSR-12 (Case-sensitive)
5. Criar código sem pensar em testes             ➔ Estrutura de testes espelhada desde o dia 1
```

> [!IMPORTANT]
> **A Regra da Previsibilidade:**  
> Uma boa arquitetura de pastas não serve para deixar o projeto "bonito", mas sim para torná-lo **previsível**. Um desenvolvedor sênior deve abrir o teu repositório e saber exatamente onde encontrar a regra de cálculo de desconto em **menos de 10 segundos**, sem precisar dar busca global por palavras-chave.

---

## 2. O Padrão Moderno no Ecossistema PHP (PSR-4 / Composer)

No PHP moderno (adotado por frameworks como Laravel, Symfony, Slim e pacotes do ecossistema Composer), a estrutura de diretórios separa rigidamente o código-fonte da aplicação, os arquivos públicos expostos à internet, configurações de infraestrutura e a suíte de testes.

Eis a árvore padrão ouro do mercado:

```text
meu-projeto/
├── .github/                      # 🤖 Automações de CI/CD (Workflows do GitHub Actions)
├── bin/                          # ⚡ Scripts executáveis de console/CLI (ex: migrations, workers)
├── config/                       # ⚙️ Arquivos de configuração centralizada (banco, rotas, DI)
│   ├── app.php                   # Parâmetros gerais da aplicação
│   ├── database.php              # Configurações de conexão PDO/MySQL
│   └── routes.php                # Declaração das rotas HTTP
├── database/                     # 🗄️ Versionamento estrutural do Banco de Dados
│   ├── migrations/               # Scripts de criação e alteração de tabelas
│   └── seeds/                    # Carga inicial de dados para testes
├── public/                       # 🌐 Raiz do Servidor Web (Único diretório servido pelo Nginx/Apache)
│   ├── index.php                 # Ponto de entrada único (Front Controller)
│   ├── .htaccess / nginx.conf    # Regras de reescrita de URL
│   └── assets/                   # CSS compilado, JS minificado, imagens e fontes
├── src/                          # 🧠 Código-Fonte da Aplicação (Mapeado estritamente via PSR-4)
│   ├── Common/                   # Utilitários compartilhados, Exceptions globais, Helpers puros
│   ├── Domain/                   # 💎 Regras de Negócio Puras (Entidades, Value Objects, Interfaces)
│   │   ├── Model/                # Entidades com identidade própria (ex: User, Order)
│   │   ├── ValueObject/          # Objetos imutáveis de valor (ex: Cpf, Email, Dinheiro)
│   │   └── Repository/           # Contratos/Interfaces (ex: UserRepositoryInterface)
│   ├── Application/              # 💼 Casos de Uso e Orquestração (UseCases, DTOs, Handlers)
│   │   ├── UseCase/              # Ações do sistema (ex: CreateUserUseCase, ProcessPaymentUseCase)
│   │   └── DTO/                  # Objetos de transferência de dados puros
│   ├── Infrastructure/           # 🔌 Adaptadores Externos e Conexões
│   │   ├── Persistence/          # Implementações de Repositórios SQL, DAOs, Mappers
│   │   ├── Cache/                # Drivers de Redis / Memcached
│   │   └── Gateways/             # Integrações com terceiros (Stripe, Correios, SendGrid)
│   └── Presentation/             # 🖥️ Portas de Entrada do Usuário / API
│       └── Http/
│           ├── Controllers/      # Controladores finos / Actions (ex: UserController.php)
│           ├── Middlewares/      # Guards de autenticação, CORS, Rate Limit
│           └── Responders/       # Formatadores de resposta JSON ou Views
├── tests/                        # 🧪 Testes Automatizados (Espelho fiel da pasta src/)
│   ├── Unit/                     # Testes unitários puros (rápidos, sem banco nem rede)
│   ├── Integration/              # Testes de persistência com banco real ou Redis
│   └── Functional/               # Testes ponta a ponta simulando requisições HTTP
├── var/                          # 📝 Arquivos transitórios gerados em runtime (Logs, Caches)
│   ├── cache/                    # Cache de templates Twig e DI Container
│   └── logs/                     # Arquivos de log diários da aplicação
├── .editorconfig                 # Padronização de tabulação e charset para qualquer editor
├── .gitignore                    # Bloqueio de arquivos sensíveis (.env, vendor/, var/)
├── .php-cs-fixer.dist.php        # Configuração do formatador automático de código (PER / PSR-12)
├── composer.json                 # Manifesto de dependências e configuração do Autoload
├── composer.lock                 # Trava de versões exatas de bibliotecas
├── phpunit.xml                   # Configuração de suítes de teste e relatórios de cobertura
└── README.md                     # Manual introdutório e guia de instalação do projeto
```

---

## 3. Como a PSR-4 Funciona Sob o Capô (e o Perigo do Linux)

O padrão **PSR-4 (PHP Standard Recommendation nº 4)** elimina a necessidade arcaica de usar `require` ou `include` no topo de cada arquivo PHP. 

Ele estabelece uma fórmula matemática direta:
$$\text{Namespace Base} + \text{Sub-namespaces} + \text{NomeDaClasse} \iff \text{Caminho no Disco} + \text{NomeDoArquivo.php}$$

### O Mapeamento no `composer.json`

```json
{
    "name": "empresa/sistema-saas",
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "App\\Tests\\": "tests/"
        }
    }
}
```

Quando o PHP encontra o código:
```php
use App\Domain\Model\User;

$user = new User();
```

O Autoloader do Composer faz a seguinte tradução automática:
1. Identifica o prefixo `"App\\"` ➔ Troca pelo diretório base `"src/"`.
2. Lê o restante do namespace `\Domain\Model\` ➔ Converte para os subdiretórios `Domain/Model/`.
3. Adiciona a extensão `.php` ao nome da classe ➔ `User.php`.
4. Carrega o arquivo: `src/Domain/Model/User.php`.

> [!WARNING]
> ### 🚨 A Armadilha do Windows vs. Linux (Case-Sensitivity)
> O sistema operacional Windows **não diferencia** maiúsculas de minúsculas (`User.php` e `user.php` são vistos como o mesmo arquivo). O Linux (onde teu servidor de produção roda) **diferencia estritamente**.
> 
> Se você nomear o arquivo como `src/Domain/Model/user.php` (minúsculo), mas declarar a classe como `class User`, no Windows o código funcionará perfeitamente. No instante em que você subir para a nuvem ou Docker no Linux, o sistema quebrará fatalmente com o erro:  
> `Fatal error: Class 'App\Domain\Model\User' not found in ...`  
> **Regra de ouro:** Mantenha namespaces, pastas e nomes de arquivos rigorosamente idênticos em *PascalCase*.

---

## 4. A Mesma Filosofia no Mundo Java (Spring Boot / Maven)

Muitos desenvolvedores acreditam que cada linguagem segue uma lógica totalmente diferente. **Isso é um mito.**

O ecossistema Java e o framework Spring Boot foram a principal inspiração histórica para o PHP criar a PSR-4 e adotar a Clean Architecture. O que no PHP chamamos de **Namespace**, no Java chamamos de **Package**. A diferença é que, no Java, o compilador exige por padrão que o nome do pacote seja estritamente igual à estrutura de diretórios no disco.

No Java com gerenciador **Maven**, a convenção padrão mundial é a seguinte:

```text
meu-projeto-spring/
├── .github/                              # CI/CD (GitHub Actions)
├── pom.xml                               # Equivalente ao composer.json (Dependências do Maven)
├── src/
│   ├── main/
│   │   ├── java/                         # 🧠 O equivalente direto à pasta "src/" do PHP
│   │   │   └── com/
│   │   │       └── empresa/
│   │   │           └── saas/             # 📦 Raiz do Package Base (Equivalente ao namespace "App\")
│   │   │               ├── SaasApplication.java # Classe com @SpringBootApplication (Main Entrypoint)
│   │   │               │
│   │   │               ├── common/       # Exceções globais, handlers e utilitários
│   │   │               │
│   │   │               ├── domain/       # 💎 Regras de Negócio Puras
│   │   │               │   ├── model/    # Entidades JPA/Domínio (ex: User.java, Order.java)
│   │   │               │   ├── valueobject/ # Objetos de Valor (ex: Cpf.java)
│   │   │               │   └── repository/  # Interfaces (ex: UserRepository.java)
│   │   │               │
│   │   │               ├── application/  # 💼 Casos de Uso e DTOs
│   │   │               │   ├── dto/      # Records/DTOs de entrada e saída
│   │   │               │   └── service/  # Serviços de aplicação / UseCases
│   │   │               │
│   │   │               ├── infrastructure/# 🔌 Conexões e Adaptadores
│   │   │               │   ├── persistence/ # Implementações Spring Data / Hibernate
│   │   │               │   └── gateway/     # Clientes de API externa (Feign, RestClient)
│   │   │               │
│   │   │               └── presentation/ # 🖥️ Porta de Entrada
│   │   │                   └── controller/  # Controladores REST com @RestController
│   │   │                       └── UserController.java
│   │   │
│   │   └── resources/                    # 🎨 Configurações e Arquivos Estáticos
│   │       ├── application.yml           # Equivalente ao .env e config/*.php
│   │       ├── static/                   # CSS, JS e imagens públicas (equivalente a public/assets/)
│   │       └── templates/                # Templates HTML (Thymeleaf - equivalente ao Twig)
│   │
│   └── test/                             # 🧪 O equivalente direto à pasta "tests/" do PHP
│       └── java/
│           └── com/
│               └── empresa/
│                   └── saas/             # Espelho exato da árvore de produção
│                       └── presentation/
│                           └── controller/
│                               └── UserControllerTest.java
└── README.md
```

---

## 5. Tabela de Equivalência: PHP vs Java

Para desenvolvedores poliglotas ou equipes multidisciplinares, veja como os conceitos se conectam perfeitamente:

| Conceito Arquitetural | PHP Moderno (PSR-4 / Slim / Laravel) | Java Moderno (Spring Boot / Maven) |
| :--- | :--- | :--- |
| **Organização Lógica** | `namespace App\Domain\Model;` | `package com.empresa.saas.domain.model;` |
| **Manifesto de Dependências** | `composer.json` | `pom.xml` (Maven) ou `build.gradle` (Gradle) |
| **Trava de Dependências** | `composer.lock` | `pom.xml` / `gradle.lockfile` |
| **Ponto de Entrada** | `public/index.php` (Front Controller) | `Application.java` (Classe `@SpringBootApplication`) |
| **Variáveis de Ambiente** | Arquivo `.env` + `config/*.php` | `application.yml` ou `application.properties` |
| **Mecanismo de Autoload** | `vendor/autoload.php` (Composer) | Classpath gerenciado pela JVM |
| **Regras de Negócio Puras** | `src/Domain/` | `src/main/java/.../domain/` |
| **Suíte de Testes** | `tests/Unit/`, `tests/Integration/` | `src/test/java/.../` |
| **Padronização de Estilo** | PHP-CS-Fixer / PHP_CodeSniffer (PER/PSR-12) | Checkstyle / Spotless / Google Java Format |
| **Gerenciador de Processos** | PHP-FPM / Nginx | Servidor Embutido (Tomcat / Jetty / Undertow) |

---

## 6. Clean Architecture, Arquitetura Hexagonal e DDD na Prática

Muitos programadores se sentem intimidados por essas siglas: **DDD**, **Clean Architecture** e **Hexagonal**. No entanto, todas elas nasceram para resolver **um único problema fundamental**:

> **"O código do meu negócio não deve depender da ferramenta que eu uso para exibi-lo ou salvá-lo."**

Se você trocar o banco de dados MySQL pelo PostgreSQL, o teu código de cálculo de juros bancários não pode sofrer uma única linha de alteração. Se você trocar a interface web em Twig por uma API REST em JSON, a entidade `Cliente` não deve mudar.

```
                  ┌────────────────────────────────────────┐
                  │          FRAMEWORKS & DRIVERS          │
                  │   (Web, Banco de Dados, UI, Redis)     │
                  │   ┌────────────────────────────────┐   │
                  │   │      INTERFACE ADAPTERS        │   │
                  │   │    (Controllers, Presenters)   │   │
                  │   │   ┌────────────────────────┐   │   │
                  │   │   │      APPLICATION       │   │   │
                  │   │   │       (Use Cases)      │   │   │
                  │   │   │   ┌────────────────┐   │   │   │
                  │   │   │   │     DOMAIN     │   │   │   │
                  │   │   │   │   (Entities,   │   │   │   │
                  │   │   │   │ Value Objects) │   │   │   │
                  │   │   │   └────────────────┘   │   │   │
                  │   │   └────────────────────────┘   │   │
                  │   └────────────────────────────────┘   │
                  └────────────────────────────────────────┘
                       ───► A REGRA DA DEPENDÊNCIA ───►
             (As camadas externas dependem apenas das mais internas.
              O núcleo [Domain] NUNCA sabe quem está do lado de fora!)
```

### 1. DDD (Domain-Driven Design) *Eric Evans*
Foca em modelar o software usando a linguagem e as regras reais do negócio (Linguagem Ubíqua):
- **Entidades:** Objetos que possuem identidade única ao longo do tempo (ex: um `Cliente` com ID 42 continua sendo o mesmo cliente mesmo se mudar de nome ou endereço).
- **Value Objects (Objetos de Valor):** Objetos imutáveis definidos unicamente pelos seus atributos (ex: `Cpf`, `Email`, `Dinheiro`). Se dois CPFs possuem o mesmo número, eles são idênticos. Não têm ID próprio.
- **Agregados (Aggregate Roots):** Um grupo de entidades tratadas como uma unidade única para garantir a consistência das regras (ex: um `Pedido` controla seus `ItensDePedido`).
- **Interfaces de Repositório:** O contrato que dita como o domínio quer salvar e recuperar dados (ex: `salvar(Pedido $pedido): void`). A interface mora no **Domínio**, mas o código SQL que executa a query mora na **Infraestrutura**!

### 2. Clean Architecture (Arquitetura Limpa) *Robert C. Martin (Uncle Bob)*
Estabelece a **Regra da Dependência**: o código interno nunca aponta para o código externo.
- O **Domain** não conhece o framework (nem Slim, nem Laravel, nem Spring).
- A **Application** conhece o Domain, mas não conhece o banco de dados.
- A **Infrastructure** conhece as interfaces e implementa os detalhes sujos (PDO, SQL, bibliotecas externas).

### 3. Arquitetura Hexagonal (Ports & Adapters) *Alistair Cockburn*
Enxerga o software como um núcleo dentro de um hexágono:
- **Portas de Entrada (Driving/Inbound Ports):** Como o mundo exterior pede coisas para o sistema (ex: Interface do Caso de Uso).
- **Adaptadores de Entrada (Driving Adapters):** O Controller HTTP, um comando CLI de terminal ou um consumidor de mensageria.
- **Portas de Saída (Driven/Outbound Ports):** O que o sistema precisa para responder (ex: Interface de envio de e-mail ou Repositório).
- **Adaptadores de Saída (Driven Adapters):** O cliente SendGrid, a conexão PDO MySQL ou o Stripe Gateway.

---

## 7. Anatomia de um Fluxo Real: Do Request HTTP ao Banco de Dados

Para visualizar como as pastas trabalham juntas de forma elegante, acompanhe a jornada de uma requisição de **Cadastro de Novo Cliente**:

```
[1. Usuário clica em 'Cadastrar']
       │ (HTTP POST /api/v1/clientes com payload JSON)
       ▼
[2. public/index.php] ──────────► [Slim 4 / Spring Boot Router]
       │
       ▼
[3. Presentation: UserController] 
       │ ➔ Extrai os dados do Request HTTP
       │ ➔ Instancia um DTO: RegisterCustomerDTO($nome, $email, $cpf)
       ▼
[4. Application: RegisterCustomerUseCase]
       │ ➔ Orquestra o caso de uso
       │ ➔ Cria os Value Objects: new Email($dto->email), new Cpf($dto->cpf)
       │ ➔ Cria a Entidade: $cliente = Customer::create(...)
       │ ➔ Consulta a Porta de Saída: $this->customerRepository->findByEmail(...)
       ▼
[5. Domain: Customer Entity & CustomerRepositoryInterface]
       │ ➔ A entidade valida suas próprias regras (ex: cliente não pode ser menor de idade)
       │ ➔ Define a interface do repositório (Porta de Saída)
       ▼
[6. Infrastructure: SqlCustomerRepository]
       │ ➔ Executa a query segura via PDO / Hibernate no MySQL
       │ ➔ Grava a linha no banco de dados
       ▼
[7. Presentation: JsonResponder] 
       │ ➔ Converte o resultado de sucesso em HTTP 201 Created
       ▼
[Usuário recebe confirmação em JSON no navegador]
```

### Por que esse fluxo é revolucionário para o desenvolvedor?
1. **Testabilidade Total:** Você pode testar o `RegisterCustomerUseCase` em **0.002 segundos** criando um repositório falso em memória (*Mock*), sem precisar que o MySQL esteja rodando.
2. **Manutenção Isolada:** Se amanhã o banco mudar de MySQL para MongoDB, você altera **apenas a pasta `Infrastructure/`**. O caso de uso, o domínio e os controllers permanecem 100% intactos!

---

## 8. A Regra de Ouro das 3 Perguntas Antes de Criar um Arquivo

Toda vez que você for criar um arquivo novo no teu projeto, pare por 5 segundos e faça a si mesmo estas três perguntas:

```
┌─────────────────────────────────────────────────────────────────────────┐
│              CHECKLIST MENTAL DO ENGENHEIRO DE SOFTWARE                 │
├─────────────────────────────────────────────────────────────────────────┤
│ 1. O que este arquivo representa?                                       │
│    • É uma regra de negócio ou modelo real?       ➔ src/Domain/         │
│    • É a execução de um processo/ação do sistema? ➔ src/Application/    │
│    • É banco de dados, API externa ou cache?      ➔ src/Infrastructure/ │
│    • É recepção de dados via HTTP ou tela?        ➔ src/Presentation/   │
├─────────────────────────────────────────────────────────────────────────┤
│ 2. Ele depende de algum framework ou tecnologia externa?                │
│    • Se depende de PDO, cURL, Redis ou SDKs, ele JAMAIS pode estar      │
│      dentro da pasta Domain/!                                           │
├─────────────────────────────────────────────────────────────────────────┤
│ 3. Onde está o teste correspondente dele?                               │
│    • Se criei src/Domain/ValueObject/Cpf.php, devo imediatamente criar  │
│      tests/Unit/Domain/ValueObject/CpfTest.php!                         │
└─────────────────────────────────────────────────────────────────────────┘
```

> **Conclusão:**  
> A excelência no desenvolvimento de software não nasce de frameworks mágicos nem de ferramentas complexas; ela nasce da **disciplina diária em manter as responsabilidades separadas**. Comece aplicando essa árvore em projetos pequenos e, quando estiver diante de um sistema de grande porte, a arquitetura trabalhará a teu favor, e não contra você.
