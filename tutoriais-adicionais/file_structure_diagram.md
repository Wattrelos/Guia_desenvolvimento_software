# 🗺️ Diagrama e Guia de Estrutura de Pastas do Projeto

> **Padrões adotados:** Clean Architecture · DDD Modular · PSR-4 · PSR-7 · PSR-11 · PSR-15
> **Stack:** PHP 8.3 · Slim 4 · PHP-DI · Twig · MySQL · Redis · RabbitMQ
> **Referência conceitual complementar:** [`006_estruturas_de_pastas.md`](../006_estruturas_de_pastas.md)

Este documento possui dois objetivos:
1. **Apresentar o mapa visual** da árvore de diretórios real do projeto.
2. **Explicar a responsabilidade** de cada pasta e subpasta, descendo até o nível folha, para que qualquer membro da equipe saiba exatamente onde criar, buscar ou mover um arquivo.

---

## 🧭 Legenda das Camadas Arquiteturais

Antes de navegar pela árvore, é fundamental entender a qual **camada** cada diretório pertence, pois a **Regra da Dependência** dita quem pode conhecer quem:

| Símbolo | Camada | Diretório Principal | Regra |
| :---: | :--- | :--- | :--- |
| 💎 | **Domain** | `backend/src/Domain/` | O núcleo puro. **Zero** dependências de frameworks, banco de dados ou bibliotecas externas. |
| 💼 | **Application** | `backend/src/Application/` | Orquestra casos de uso. Conhece o Domain, mas **nunca** o banco ou o HTTP. |
| 🔌 | **Infrastructure** | `backend/src/Infrastructure/` | Implementa os contratos do Domain. É o único lugar permitido para PDO, Redis, cURL, etc. |
| 🌐 | **Http** | `backend/src/Http/` | Porta de entrada HTTP. Conhece a Application via DTOs/Use Cases. **Não** contém regras de negócio. |
| 🎨 | **Resources** | `backend/resources/` | Templates Twig e arquivos de internacionalização. Sem lógica PHP. |

---

## 📐 Diagrama de Fluxo de Dependências

A seta `──►` representa a direção da dependência permitida. Uma camada **só pode apontar para dentro**, nunca para fora.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CAMADAS EXTERNAS                             │
│                                                                     │
│   [Http / Controllers]  ──►  [Application / Use Cases]             │
│                                      │                             │
│   [Infrastructure / Repositories] ──►│                             │
│                                      ▼                             │
│                           [Domain / Entities,                       │
│                            Value Objects, Interfaces]               │
│                                                                     │
│   ◄── As setas só apontam para dentro. O Domain nunca               │
│        sabe quem está do lado de fora.                              │
└─────────────────────────────────────────────────────────────────────┘
```

**Leitura prática:**
- O `Http` chama o `Application` (Use Cases) e nunca toca diretamente no `Domain`.
- O `Application` coordena entidades e interfaces do `Domain`, mas nunca sabe qual banco de dados está sendo usado.
- O `Infrastructure` implementa as interfaces declaradas no `Domain` (Repositórios, Gateways), sendo o único lugar com código "sujo" (PDO, SDKs, HTTP clients).
- O `Domain` não importa nenhuma classe de nenhuma outra camada.

---

## 🌲 Estrutura de Pastas Utilizada Neste Projeto

> Este é um exemplo de estrutura de pastas utilizada neste projeto, que segue os padrões do Clean Architecture e DDD Modular e PSR-15.

```
@startfiles
.
├── .env.example                                # 🔑 Modelo oficial de variáveis de ambiente do projeto
├── composer.json                               # 📦 Manifesto de dependências e autoloader PSR-4
├── composer.lock                               # 🔒 Bloqueio de versões exatas de dependências
├── phpunit.xml                                 # 🧪 Configuração de suites de testes automatizados
├── README.md                                   # 📖 Documentação introdutória do projeto
│
├── backend/                                    # 📁 Backend (Clean Architecture / DDD Modular / PSR-15)
│   ├── config/                                 # 📂 Configurações centralizadas da aplicação
│   │   ├── app.php                             # ⚙️ Parâmetros gerais do sistema e ambiente
│   │   ├── database.php                        # 🗄️ Conexão com banco de dados MySQL
│   │   ├── dependencies.php                    # 📦 Injeção de Dependências PSR-11 (PHP-DI)
│   │   ├── middleware.php                      # 🧱 Pipeline global de Middlewares PSR-15
│   │   └── routes/                             # 🚦 Rotas desacopladas por contexto de aplicação
│   │       ├── admin.php                       # 🛡️ Rotas do Painel Administrativo
│   │       ├── api.php                         # 🤖 Rotas RESTful da API v1
│   │       ├── pos.php                         # 🛒 Rotas do Ponto de Venda (PDV)
│   │       └── storefront.php                  # 🛍️ Rotas da Loja Virtual (E-commerce)
│   │
│   ├── src/                                    # 🏛️ Código-Fonte Autoloaded (Namespace: App\ ou BetaEngine\)
│   │   │
│   │   ├── Domain/                             # 💎 Camada Enterprise (Regras de Negócio Puras - Zero Dependências)
│   │   │   ├── Shared/                         # 🌐 Elementos compartilhados entre agregados
│   │   │   │   ├── Enums/                      # 🏷️ Enumerações de status, tipos e estados
│   │   │   │   ├── Events/                     # 📣 Eventos de domínio (Domain Events)
│   │   │   │   └── ValueObjects/               # 💎 Objetos de Valor (Money, Email, CpfCnpj, Address, Id)
│   │   │   │
│   │   │   ├── Catalog/                        # 📦 Bounded Context: Catálogo de Produtos
│   │   │   │   ├── Entities/                   # 🏛️ Entidades (Product, Category, Manufacturer)
│   │   │   │   ├── Events/                     # 📣 Eventos (ProductPriceChanged, StockDepleted)
│   │   │   │   └── Repositories/               # 📜 Interfaces/Contratos de Repositório (ProductRepositoryInterface)
│   │   │   │
│   │   │   ├── Customer/                       # 👤 Bounded Context: Clientes e CRM
│   │   │   │   ├── Entities/                   # 🏛️ Entidades (Customer, CustomerAddress, CustomerHistory)
│   │   │   │   └── Repositories/               # 📜 Interfaces (CustomerRepositoryInterface)
│   │   │   │
│   │   │   ├── Order/                          # 🧾 Bounded Context: Vendas e Pedidos
│   │   │   │   ├── Entities/                   # 🏛️ Entidades (Order, OrderItem, OrderHistory)
│   │   │   │   ├── Aggregates/                 # 🧱 Raiz de Agregação do Pedido (OrderAggregate)
│   │   │   │   └── Repositories/               # 📜 Interfaces (OrderRepositoryInterface)
│   │   │   │
│   │   │   ├── Cart/                           # 🛒 Bounded Context: Carrinho de Compras
│   │   │   │   ├── Entities/                   # 🏛️ Entidades (Cart, CartItem)
│   │   │   │   └── Repositories/               # 📜 Interfaces (CartRepositoryInterface)
│   │   │   │
│   │   │   ├── POS/                            # 🏪 Bounded Context: Ponto de Venda
│   │   │   │   ├── Entities/                   # 🏛️ Entidades (PreSale, CashRegister, SaleSession)
│   │   │   │   └── Repositories/               # 📜 Interfaces (PreSaleRepositoryInterface)
│   │   │   │
│   │   │   ├── Procurement/                    # 🚛 Bounded Context: Compras e Fornecedores
│   │   │   │   ├── Entities/                   # 🏛️ Entidades (Supplier, PurchaseOrder)
│   │   │   │   └── Repositories/               # 📜 Interfaces (SupplierRepositoryInterface)
│   │   │   │
│   │   │   └── Security/                       # 🔐 Bounded Context: Acesso e Permissões (RBAC)
│   │   │       ├── Entities/                   # 🏛️ Entidades (AdminUser, Role, Permission)
│   │   │       └── Repositories/               # 📜 Interfaces (UserRepositoryInterface)
│   │   │
│   │   ├── Application/                        # 💼 Camada de Aplicação (Casos de Uso e Orquestração)
│   │   │   ├── Common/                         # 🛠️ Interfaces de barramentos e handlers comuns
│   │   │   ├── Catalog/                        # 📦 Casos de Uso do Catálogo
│   │   │   │   ├── DTOs/                       # 📋 DTOs de Entrada e Saída (ProductSearchDTO, ProductResponseDTO)
│   │   │   │   └── UseCases/                   # ⚙️ Casos de Uso (SearchCatalogUseCase, GetProductDetailsUseCase)
│   │   │   ├── Customer/                       # 👤 Casos de Uso de Clientes
│   │   │   │   ├── DTOs/                       # 📋 DTOs (RegisterCustomerDTO, UpdateAddressDTO)
│   │   │   │   └── UseCases/                   # ⚙️ Casos de Uso (RegisterCustomerUseCase, AuthenticateUseCase)
│   │   │   ├── Order/                          # 🧾 Casos de Uso de Pedidos
│   │   │   │   ├── DTOs/                       # 📋 DTOs (CheckoutDTO, OrderSummaryDTO)
│   │   │   │   └── UseCases/                   # ⚙️ Casos de Uso (ProcessCheckoutUseCase, CancelOrderUseCase)
│   │   │   └── POS/                            # 🏪 Casos de Uso de PDV
│   │   │       ├── DTOs/                       # 📋 DTOs (CreatePreSaleDTO, ProcessPaymentDTO)
│   │   │       └── UseCases/                   # ⚙️ Casos de Uso (EmitPreSaleTicketUseCase, FinalizeSaleUseCase)
│   │   │
│   │   ├── Infrastructure/                     # 🔌 Camada de Infraestrutura e Adaptadores Externos
│   │   │   ├── Persistence/                    # 🗄️ Acesso a Dados e Mapeamento Objeto-Relacional
│   │   │   │   ├── Connection/                 # 🔌 Gerenciador de conexão PDO/MySQL
│   │   │   │   ├── QueryBuilder/               # 🔍 Construtor de queries seguras e parametrizadas
│   │   │   │   ├── UnitOfWork/                 # 🔄 Padrão Unit of Work e Identity Map
│   │   │   │   ├── Mappers/                    # 🗺️ Data Mappers (Tradutores SQL ⇄ Entidades de Domínio)
│   │   │   │   └── Repositories/               # 🗃️ Implementação concreta dos repositórios via SQL
│   │   │   ├── Cache/                          # ⚡ Adaptadores de Cache (RedisAdapter, MemoryAdapter)
│   │   │   ├── Messaging/                      # 📬 Mensageria e Filas Assíncronas (RabbitMQ, EventPublisher)
│   │   │   ├── Security/                       # 🛡️ Criptografia, Hasher Argon2id e Provedor JWT
│   │   │   └── Gateways/                       # 🌐 Clientes de Serviços Externos
│   │   │       ├── Payments/                   # 💳 Adaptadores de Pagamento (Stripe, Pix, TEF)
│   │   │       ├── Shipping/                   # 🚚 Adaptadores de Frete (Correios, Transportadoras)
│   │   │       └── Fiscal/                     # 🧾 Adaptadores Fiscais (NFC-e / SEFAZ)
│   │   │
│   │   └── Http/                               # 🌐 Camada de Entrada e Apresentação HTTP (PSR-7 / PSR-15)
│   │       ├── Middlewares/                    # 🧱 Middlewares HTTP (Guards, CSRF, Auth, RateLimit)
│   │       ├── Responders/                     # 🎯 Responders ADR (TwigResponder, JsonApiResponse, RedirectResponse)
│   │       └── Controllers/                    # 🎮 Action Controllers desacoplados por contexto
│   │           ├── Storefront/                 # 🛍️ Actions da Loja (Catalog, Cart, Checkout, Account)
│   │           ├── Admin/                      # 🛡️ Actions do Painel (Dashboard, Catalog, Sales, CRM, Settings)
│   │           ├── POS/                        # 🏪 Actions do PDV (SalesRep, Cashier)
│   │           └── Api/                        # 🤖 Actions da API RESTful (v1)
│   │
│   └── resources/                              # 🎨 Recursos Estáticos Não-Compilados e Views
│       ├── locales/                            # 🌐 Arquivos de Internacionalização i18n
│       │   ├── en-gb/                          # 🇬🇧 Inglês
│       │   ├── es-es/                          # 🇪🇸 Espanhol
│       │   └── pt-br/                          # 🇧🇷 Português do Brasil (Padrão)
│       └── views/                              # 🖼️ Templates Twig (Padronização Estrita Kebab-Case)
│           ├── components/                     # 🧩 Atomic Design Global
│           │   ├── atoms/                      # 🔬 Botões, inputs, badges, ícones
│           │   ├── molecules/                  # 🧬 Cards de produto, searchbars, alertas
│           │   └── organisms/                  # 🧱 Headers, footers, tabelas de listagem
│           ├── layouts/                        # 📐 Layouts base compartilhados (base, auth, error)
│           ├── storefront/                     # 🛍️ Templates da Loja Virtual
│           │   ├── components/                 # 🧩 Componentes exclusivos do Storefront
│           │   │   ├── atoms/                  # Botão de compra, badge de desconto
│           │   │   └── molecules/              # Card de produto, mini-carrinho
│           │   ├── catalog/                    # 📦 Listagem de produtos, busca, categorias
│           │   ├── checkout/                   # 💳 Telas de carrinho, endereço e pagamento
│           │   └── customer/                   # 👤 Painel do cliente e autenticação
│           ├── admin/                          # 🛡️ Templates do Backoffice
│           │   ├── components/                 # 🧩 Componentes exclusivos do Storefront
│           │   │   ├── atoms/                  # Botão de ação rápida, badge de status de pedido
│           │   │   └── molecules/              # Widget de gráfico, linha de tabela de métricas
│           │   ├── catalog/                    # 🗄️ Gestão de produtos, categorias, marcas
│           │   ├── crm/                        # 💼 Gestão de clientes e aprovações
│           │   ├── dashboard/                  # 📊 Visão geral e métricas de vendas
│           │   ├── sales/                      # 🧾 Gestão de pedidos e notas
│           │   └── settings/                   # ⚙️ Parâmetros gerais e de loja
│           └── pos/                            # 🏪 Templates do Ponto de Venda
│               ├── cashier/                    # 💰 Interface do Operador de Caixa
│               └── sales-rep/                  # 🧑‍💼 Interface do Vendedor de Balcão
│
├── public_html/                                # 🌐 Webroot (Único Document Root Exposto na Hospedagem)
│   ├── index.php                               # 🚀 Front Controller Único (Roteia Store, Admin, POS e API)
│   ├── robots.txt                              # 🤖 Diretivas de indexação para motores de busca
│   ├── favicon.ico                             # 🌐 Ícone da aplicação
│   ├── assets/                                 # 🎨 Assets Públicos Estáticos Compilados
│   │   ├── css/                                # 🎨 Folhas de estilo compiladas/minificadas
│   │   ├── js/                                 # ⚡ Bundles JavaScript otimizados
│   │   └── fonts/                              # 🔤 Fontes locais e tipografias
│   └── adm_[PASSWORD]/                         # 🛡️ Root público do painel administrativa (ofuscado p/ segurança)
│
# --------------- << Arquivos que não irão para a produção >>
├── database/                                   # 🗄️ Controle e Versionamento do Banco de Dados
│   ├── migrations/                             # 📂 Scripts de criação e migração de tabelas
│   ├── seeds/                                  # 📂 Dados sementes de povoamento inicial
│   └── schemas/                                # 📂 Modelos conceituais e diagramas relacionais
│
├── docs/                                       # 📚 Central Unificada de Documentação do Projeto
│   ├── architecture/                           # 🏗️ Visão arquitetural, ADRs e diagramas técnicos
│   │   ├── adr/                                # 📝 Architecture Decision Records (Registros de Decisões)
│   │   ├── components/                         # 🧩 Componentes da arquitetura
│   │   ├── deployment/                         # 🚀 Manuais de deploy e infraestrutura
│   │   ├── reviews/                            # 📋 Revisões de código e arquitetura
│   │   └── file_structure_diagram.puml         # 🗺️ Mapa da arquitetura)
│   ├── business/                               # 💼 Regras de negócio, glossário e processos
│   │   └── processes/                          # 🔄 Diagramas de processo
│   │   └── use-cases/                          # 📋 Casos de uso do sistema
│   ├── database/                               # 🗄️ Diagramas ER/EER e dicionário de dados
│   ├── diagrams/                               # 📊 Diagramas gerais para stakeholders e engenharia
│   ├── DoD/                                    # 📋 Definition of Done
│   ├── domain/                                 # 🧩 Domínios de negócio
│   │   └── roles/                              # 📜 Subpasta específica para os papéis (cargos, funções ou atores) que interagem dentro desse domínio de negócio.
│   ├── issues/                                 # 📋 Subpasta específica para centralização dos arquivos issues.
│   ├── kb/                                     # 📋 Subpasta específica para centralização dos arquivos de conhecimento.
│   ├── legal/                                  # 📋 Subpasta específica para centralização dos arquivos legais.
│   │   └── labor-opinions/                     # 📋 Subpasta específica para centralização dos arquivos de laudos e pareceres técnicos.
│   ├── migrations/                             # 📋 Subpasta específica para centralização dos arquivos de migração.
│   ├── requirements/                           # 📋 Requisitos do sistema
│   │   ├── business-rules/                     # 📋 Subpasta específica para centralização das regras de negócio.
│   │   ├── functional/                         # 📋 Requisitos funcionais
│   │   └── non-functional/                     # 📋 Requisitos não funcionais
│   ├── specs/                                  # 📋 Especificações formais (OpenAPI 3.1, BDD Gherkin)
│   │   ├── features/                           # 📋 Especificações formais (OpenAPI 3.1, BDD Gherkin)
│   │   └── schemas/                            # 📋 Especificações formais (OpenAPI 3.1, BDD Gherkin)
│   └── workflows/                              # 🔄 Diagramas de sequência e atividade
│       ├── activity-diagrams/                  # 🔄 Diagramas de atividade
│       └── sequence-diagrams/                  # 🔄 Diagramas de sequência
│
├── scripts/                                    # 🛠️ Utilitários de DevOps, Deploy, CI e Manutenção
│   ├── devops/                                 # 🚢 Scripts de provisionamento e deploy
│   └── workers/                                # ⚙️ Scripts de execução de filas CLI (RabbitMQ Workers)
│
└── tests/                                      # 🧪 Pirâmide Completa de Testes Automatizados (PHPUnit)
    ├── Unit/                                   # 🔬 Testes Unitários de Regras de Domínio (Sem Banco)
    ├── Integration/                            # 🧩 Testes de Integração (Banco de Dados, Mappers, Cache)
    ├── Functional/                             # 🚦 Testes Funcionais de Rotas e Middlewares HTTP
    └── E2E/                                    # 🎭 Testes Ponta a Ponta de Fluxos Críticos
@endfiles
```

---

## 📖 Função de Cada Pasta

Esta seção descreve a **responsabilidade única** de cada diretório, o que pode e o que **não** pode residir nele.

---

### 📌 Raiz do Projeto (`.`)

A raiz contém apenas os arquivos de configuração de nível de projeto — aqueles que ferramentas de linha de comando, CI/CD e o ambiente precisam encontrar na raiz para funcionar corretamente.

| Arquivo | Responsabilidade |
| :--- | :--- |
| `.env.example` | Modelo oficial de variáveis de ambiente. Commitado no repositório. O arquivo `.env` real (com senhas e chaves) **nunca** é versionado. |
| `composer.json` | Manifesto de dependências PHP e mapa de autoload PSR-4. Define também scripts de conveniência (`composer test`, `composer cs-fix`). |
| `composer.lock` | Trava as versões exatas de cada pacote instalado, garantindo reprodutibilidade em qualquer máquina ou pipeline de CI/CD. |
| `phpunit.xml` | Configura as suítes de teste (Unit, Integration, Functional, E2E), paths de bootstrap e relatórios de cobertura. |
| `README.md` | Porta de entrada do repositório: instruções de instalação, pré-requisitos e guia de início rápido para novos desenvolvedores. |

> **Não coloque na raiz:** lógica de negócio, controllers, configurações específicas de módulo, arquivos de template ou qualquer arquivo `.php` que não seja de bootstrapping.

---

### ⚙️ `backend/config/`

Centraliza **todos os parâmetros de montagem da aplicação**. É lida uma única vez durante o bootstrap e não contém regras de negócio — apenas configuração.

#### `backend/config/app.php`
Define os parâmetros gerais do sistema: nome da aplicação, ambiente (`production`, `development`, `testing`), timezone, nível de log e quaisquer flags de feature toggle. É o equivalente ao `application.yml` do Spring Boot.

#### `backend/config/database.php`
Centraliza as credenciais e opções de conexão com o banco de dados MySQL (DSN, charset, timeout, modo de erro PDO). As credenciais em si são lidas a partir do `.env`, nunca hardcoded aqui.

#### `backend/config/dependencies.php`
Define o container de Injeção de Dependências (PHP-DI / PSR-11). É aqui que se declara **como** cada interface do Domain é resolvida para uma implementação concreta da Infrastructure — por exemplo, `CustomerRepositoryInterface` → `SqlCustomerRepository`. Esta é a única cola entre as camadas Domain e Infrastructure.

#### `backend/config/middleware.php`
Declara o pipeline global de middlewares PSR-15 que será executado em **toda** requisição HTTP, independentemente da rota: autenticação de sessão, CSRF, Content-Type, logging de acesso, etc.

#### `backend/config/routes/`
Separa as declarações de rotas por contexto de negócio, evitando um único arquivo monstruoso.

| Arquivo | Contexto |
| :--- | :--- |
| `admin.php` | Rotas do painel administrativo (backoffice), prefixadas com `/adm_[PASSWORD]/` |
| `api.php` | Rotas RESTful públicas e autenticadas por token (prefixo `/api/v1/`) |
| `pos.php` | Rotas do Ponto de Venda (PDV), acessadas em rede interna |
| `storefront.php` | Rotas da loja virtual voltadas ao cliente final |

> **Não coloque aqui:** lógica de negócio, chamadas ao banco de dados, validações ou código que deveria estar em um Use Case.

---

### 💎 `backend/src/Domain/`

O **núcleo imutável do sistema**. Contém exclusivamente as regras, modelos e contratos que expressam o negócio na sua linguagem mais pura. Esta camada **não importa** nenhuma biblioteca externa, nenhum framework e nenhuma classe de infraestrutura.

> [!CAUTION]
> **Regra absoluta:** se um arquivo nesta pasta tiver um `use` apontando para `Slim\`, `PDO`, `Redis` ou qualquer SDK de terceiro, isso é um erro arquitetural grave.

#### `backend/src/Domain/Shared/`

Elementos de domínio que são transversais a todos os Bounded Contexts.

##### `backend/src/Domain/Shared/Enums/`
Enumerações PHP 8.1+ que representam estados, tipos e categorias válidos para o negócio. Por exemplo: `OrderStatus` (pending, paid, shipped, cancelled), `PaymentMethod` (pix, credit_card, cash), `UserRole` (admin, cashier, sales_rep). São tipos seguros que substituem constantes mágicas espalhadas pelo código.

##### `backend/src/Domain/Shared/Events/`
Interfaces e classes base dos **Domain Events** — registros imutáveis de que algo significativo aconteceu no domínio. Um evento representa um fato passado: `OrderWasPlaced`, `CustomerWasRegistered`. Eles não contêm comportamento; são apenas mensageiros de dados. Os subscribers que reagem a eles ficam na camada de Application ou Infrastructure.

##### `backend/src/Domain/Shared/ValueObjects/`
Objetos de valor imutáveis que são compartilhados entre múltiplos Bounded Contexts. Exemplos:
- `Money` — encapsula valor e moeda, garantindo que operações monetárias (como soma de preços) sejam sempre precisas e seguras.
- `Email` — valida o formato e garante que nenhum e-mail inválido entre no sistema.
- `CpfCnpj` — valida e formata o documento fiscal brasileiro.
- `Address` — agrupa logradouro, bairro, cidade, estado e CEP como uma unidade coesa.
- `Id` — Identificador único universal (UUID v4) tipado, evitando confundir o ID de um `Customer` com o ID de um `Product`.

#### `backend/src/Domain/Catalog/`

Bounded Context responsável pelo catálogo de produtos, categorias e fabricantes.

##### `backend/src/Domain/Catalog/Entities/`
Entidades com identidade própria que representam os objetos de negócio do catálogo:
- `Product` — o produto em si, com nome, preço, estoque e referências a categoria e fabricante.
- `Category` — a hierarquia de classificação dos produtos (pode ser recursiva, com subcategorias).
- `Manufacturer` — o fabricante ou marca do produto.

##### `backend/src/Domain/Catalog/Events/`
Eventos de domínio disparados quando algo significativo acontece no catálogo:
- `ProductPriceChanged` — disparado quando o preço de um produto é alterado, podendo acionar recálculos de carrinho.
- `StockDepleted` — disparado quando o estoque de um produto chega a zero, podendo acionar alertas de reposição.

##### `backend/src/Domain/Catalog/Repositories/`
Interfaces (contratos) que declaram **o que** a aplicação precisa de persistência, sem ditar **como** será feito:
- `ProductRepositoryInterface` — define operações como `findById`, `findByCategory`, `save`, `delete`.

#### `backend/src/Domain/Customer/`

Bounded Context responsável pelos dados, histórico e comportamento dos clientes do sistema.

##### `backend/src/Domain/Customer/Entities/`
- `Customer` — o cliente com seus dados pessoais, documentos e status de conta.
- `CustomerAddress` — endereços de entrega e cobrança vinculados a um cliente.
- `CustomerHistory` — registro histórico de interações e compras do cliente.

##### `backend/src/Domain/Customer/Repositories/`
- `CustomerRepositoryInterface` — define operações como `findByEmail`, `findByCpf`, `save`.

#### `backend/src/Domain/Order/`

Bounded Context responsável por todo o ciclo de vida de um pedido: criação, pagamento, faturamento e cancelamento.

##### `backend/src/Domain/Order/Entities/`
- `Order` — a entidade raiz do pedido, com status, totais, forma de pagamento e referência ao cliente.
- `OrderItem` — cada linha do pedido, contendo referência ao produto, quantidade e preço unitário capturado no momento da venda.
- `OrderHistory` — log imutável de cada mudança de status do pedido.

##### `backend/src/Domain/Order/Aggregates/`
- `OrderAggregate` — a **Raiz de Agregação** (Aggregate Root). Toda operação que modifica um pedido passa exclusivamente por aqui. O agregado garante a consistência das invariantes de negócio: por exemplo, não é possível adicionar itens a um pedido já pago ou cancelado. Nenhum código externo manipula `OrderItem` diretamente — apenas o `OrderAggregate` tem esse direito.

##### `backend/src/Domain/Order/Repositories/`
- `OrderRepositoryInterface` — define operações como `findById`, `findByCustomer`, `save`.

#### `backend/src/Domain/Cart/`

Bounded Context responsável pelo carrinho de compras temporário, que existe antes da confirmação do pedido.

##### `backend/src/Domain/Cart/Entities/`
- `Cart` — o carrinho vinculado a uma sessão ou cliente, com cálculo de subtotal e validação de estoque.
- `CartItem` — cada item adicionado ao carrinho, com quantidade e preço atual.

##### `backend/src/Domain/Cart/Repositories/`
- `CartRepositoryInterface` — define operações como `findBySessionId`, `save`, `clear`.

#### `backend/src/Domain/POS/`

Bounded Context do Ponto de Venda físico, com regras diferentes do e-commerce (pré-venda, caixa, sessão de vendas).

##### `backend/src/Domain/POS/Entities/`
- `PreSale` — a pré-venda gerada pelo vendedor de balcão antes da finalização no caixa.
- `CashRegister` — representa o caixa físico com seu saldo de abertura, movimentações e fechamento.
- `SaleSession` — a sessão de turno do operador de caixa, agrupando todas as vendas de um período.

##### `backend/src/Domain/POS/Repositories/`
- `PreSaleRepositoryInterface` — contratos para persistência e recuperação de pré-vendas.

#### `backend/src/Domain/Procurement/`

Bounded Context de compras e relacionamento com fornecedores.

##### `backend/src/Domain/Procurement/Entities/`
- `Supplier` — o fornecedor com seus dados comerciais, contatos e condições de pagamento.
- `PurchaseOrder` — a ordem de compra emitida para o fornecedor, com itens, quantidades e preços negociados.

##### `backend/src/Domain/Procurement/Repositories/`
- `SupplierRepositoryInterface` — contratos para busca e persistência de fornecedores.

#### `backend/src/Domain/Security/`

Bounded Context de controle de acesso baseado em papéis (RBAC — Role-Based Access Control).

##### `backend/src/Domain/Security/Entities/`
- `AdminUser` — o usuário administrativo com credenciais, papel e permissões.
- `Role` — o papel (perfil de acesso) que agrupa um conjunto de permissões (ex: `Administrador`, `Operador de Caixa`).
- `Permission` — uma permissão atômica e nomeada (ex: `catalog.products.edit`, `orders.cancel`).

##### `backend/src/Domain/Security/Repositories/`
- `UserRepositoryInterface` — contratos para busca de usuário por credencial, papel e permissão.

---

### 💼 `backend/src/Application/`

A camada de **orquestração**. Cada Use Case aqui implementa exatamente um caso de uso do sistema (uma história de usuário, um item do backlog). Ele coordena entidades do Domain, chama interfaces de repositório e, ao final, retorna um DTO de resposta — nunca um objeto de domínio diretamente para a camada HTTP.

> [!IMPORTANT]
> **Regra:** nenhum Use Case pode instanciar um objeto PDO, chamar `curl_exec` ou depender de uma classe concreta de infraestrutura. Ele trabalha **exclusivamente** com interfaces declaradas no Domain.

#### `backend/src/Application/Common/`
Interfaces e classes base compartilhadas entre todos os Use Cases: interface de barramento de comandos (`CommandBusInterface`), interface de barramento de eventos (`EventBusInterface`), e classes base de exceção de aplicação.

#### `backend/src/Application/Catalog/`

##### `backend/src/Application/Catalog/DTOs/`
Objetos simples de transferência de dados do contexto de catálogo:
- `ProductSearchDTO` — carrega os critérios de busca recebidos do HTTP (termo, categoria, ordenação, paginação).
- `ProductResponseDTO` — estrutura de saída com os dados do produto a ser retornado pela API ou renderizado no template.

##### `backend/src/Application/Catalog/UseCases/`
- `SearchCatalogUseCase` — recebe um `ProductSearchDTO`, consulta o repositório e retorna uma coleção paginada.
- `GetProductDetailsUseCase` — busca um produto pelo seu ID e retorna seus detalhes completos.
- `CreateProductUseCase` — valida os dados recebidos, cria a entidade `Product` e a persiste via repositório.
- `UpdateProductUseCase` — localiza o produto, aplica as mudanças respeitando as invariantes de negócio e persiste.

#### `backend/src/Application/Customer/`

##### `backend/src/Application/Customer/DTOs/`
- `RegisterCustomerDTO` — dados necessários para cadastrar um novo cliente (nome, e-mail, CPF, senha).
- `UpdateAddressDTO` — dados para adicionar ou atualizar um endereço de entrega.

##### `backend/src/Application/Customer/UseCases/`
- `RegisterCustomerUseCase` — valida unicidade de e-mail e CPF, cria a entidade `Customer` e a persiste.
- `AuthenticateUseCase` — verifica credenciais contra o hash armazenado e retorna o token JWT.

#### `backend/src/Application/Order/`

##### `backend/src/Application/Order/DTOs/`
- `CheckoutDTO` — dados do carrinho, endereço de entrega e forma de pagamento para iniciar o checkout.
- `OrderSummaryDTO` — estrutura de saída com o resumo do pedido confirmado.

##### `backend/src/Application/Order/UseCases/`
- `ProcessCheckoutUseCase` — o Use Case mais complexo do sistema. Valida estoque, calcula frete, processa pagamento via Gateway e cria o `Order` via `OrderAggregate`.
- `CancelOrderUseCase` — verifica se o pedido pode ser cancelado, executa o estorno e atualiza o status.

#### `backend/src/Application/POS/`

##### `backend/src/Application/POS/DTOs/`
- `CreatePreSaleDTO` — dados dos itens selecionados pelo vendedor para gerar o ticket de pré-venda.
- `ProcessPaymentDTO` — dados da forma de pagamento escolhida na finalização no caixa.

##### `backend/src/Application/POS/UseCases/`
- `EmitPreSaleTicketUseCase` — cria a `PreSale`, reserva o estoque temporariamente e gera o ticket para impressão.
- `FinalizeSaleUseCase` — converte a pré-venda em `Order` definitivo, debita o estoque e registra no caixa.

---

### 🔌 `backend/src/Infrastructure/`

A camada dos **detalhes técnicos**. Tudo que depende de uma tecnologia específica (MySQL, Redis, RabbitMQ, Stripe, Correios) mora aqui. Esta é a única camada que implementa as interfaces declaradas no Domain.

#### `backend/src/Infrastructure/Persistence/`

##### `backend/src/Infrastructure/Persistence/Connection/`
Gerencia o ciclo de vida da conexão PDO com o MySQL: criação da instância singleton, configuração de charset (`utf8mb4`), modo de erro (`ERRMODE_EXCEPTION`) e gerenciamento de transações.

##### `backend/src/Infrastructure/Persistence/QueryBuilder/`
Um construtor de queries SQL fluente e parametrizado que previne SQL Injection. Permite construir `SELECT`, `INSERT`, `UPDATE` e `DELETE` de forma programática, sem concatenação de strings.

##### `backend/src/Infrastructure/Persistence/UnitOfWork/`
Implementa o padrão **Unit of Work**: rastreia todas as entidades carregadas durante uma requisição em um **Identity Map** (evitando carregar o mesmo registro duas vezes do banco) e gerencia o commit ou rollback de todas as mudanças em uma única transação de banco ao final do fluxo.

##### `backend/src/Infrastructure/Persistence/Mappers/`
Os **Data Mappers** são os tradutores entre o mundo relacional (arrays de colunas SQL) e o mundo orientado a objetos (entidades de domínio). Um `CustomerMapper`, por exemplo, transforma um `array` com colunas `id`, `full_name`, `email_address` na entidade `Customer` com seus Value Objects devidamente instanciados — e vice-versa.

##### `backend/src/Infrastructure/Persistence/Repositories/`
As implementações concretas de cada interface de repositório declarada no Domain. Por exemplo, `SqlCustomerRepository` implementa `CustomerRepositoryInterface` usando PDO e o `CustomerMapper`. Nenhuma outra parte do sistema (exceto o container de DI) sabe que esta classe existe.

#### `backend/src/Infrastructure/Cache/`
Adaptadores de cache que implementam uma interface comum (`CacheInterface`):
- `RedisAdapter` — armazena e recupera dados do Redis para cache de sessão, resultado de queries e filas.
- `MemoryAdapter` — cache em memória para testes, sem dependência de servidor externo.

#### `backend/src/Infrastructure/Messaging/`
Integração com o sistema de filas assíncronas:
- `RabbitMQPublisher` — publica eventos de domínio (como `OrderWasPlaced`) em exchanges do RabbitMQ para processamento assíncrono.
- `EventPublisher` — implementação da interface `EventBusInterface` que determina se o evento vai para o RabbitMQ ou é processado sincronamente.

#### `backend/src/Infrastructure/Security/`
Implementações concretas dos serviços de segurança:
- `Argon2idHasher` — usa o algoritmo Argon2id (recomendado pelo OWASP) para hash seguro de senhas.
- `JwtProvider` — gera, assina e valida tokens JWT para autenticação stateless da API.

#### `backend/src/Infrastructure/Gateways/`

##### `backend/src/Infrastructure/Gateways/Payments/`
Adaptadores de pagamento que implementam uma `PaymentGatewayInterface` comum:
- `StripeGateway` — integração com a API do Stripe para cartão de crédito internacional.
- `PixGateway` — geração de QR Code Pix via API bancária.
- `TefGateway` — integração com terminal TEF (Transferência Eletrônica de Fundos) para o PDV físico.

##### `backend/src/Infrastructure/Gateways/Shipping/`
Adaptadores de frete que implementam uma `ShippingGatewayInterface`:
- `CorreiosGateway` — consulta de prazos e preços via Web Service dos Correios.
- Adaptadores adicionais para transportadoras privadas (Jadlog, Total Express, etc.).

##### `backend/src/Infrastructure/Gateways/Fiscal/`
Adaptadores para obrigações fiscais:
- `NfceGateway` — emissão e cancelamento de NFC-e (Nota Fiscal de Consumidor Eletrônica) via SEFAZ.
- Comunicação com o SEFAZ estadual para transmissão e recepção de eventos fiscais.

---

### 🌐 `backend/src/Http/`

A porta de entrada HTTP da aplicação. Recebe requisições PSR-7, extrai dados, delega para a camada de Application e formata a resposta. Esta camada **não tem regras de negócio** — apenas orquestração de entrada/saída HTTP.

#### `backend/src/Http/Middlewares/`
Middlewares PSR-15 executados no pipeline de cada requisição (além dos globais em `config/middleware.php`):
- `AuthGuardMiddleware` — verifica o token JWT e rejeita acessos não autenticados com `401 Unauthorized`.
- `CsrfMiddleware` — valida tokens CSRF em formulários HTML.
- `RateLimitMiddleware` — limita o número de requisições por IP/usuário em um intervalo de tempo.
- `PermissionMiddleware` — verifica se o usuário autenticado possui a permissão necessária para a rota.

#### `backend/src/Http/Responders/`
Implementam o padrão **ADR (Action-Domain-Responder)**, separando a lógica de formatação da resposta do Controller:
- `TwigResponder` — renderiza templates `.twig` e retorna uma resposta HTML com o status correto.
- `JsonApiResponder` — serializa dados em JSON seguindo as convenções da API (envelope, paginação, erros).
- `RedirectResponder` — gera respostas de redirecionamento (301, 302) com cabeçalho `Location`.

#### `backend/src/Http/Controllers/`
Os **Action Controllers** — cada Controller (ou Action, no padrão ADR) é responsável por exatamente uma ação do sistema. Eles são magros: recebem a requisição PSR-7, montam o DTO, chamam o Use Case e devolvem a resposta ao Responder.

##### `backend/src/Http/Controllers/Storefront/`
Actions da loja virtual voltadas ao cliente final: listagem de catálogo (`CatalogAction`), página de produto (`ProductDetailAction`), gerenciamento de carrinho (`AddToCartAction`, `RemoveFromCartAction`), fluxo de checkout (`CheckoutAction`) e área do cliente (`CustomerDashboardAction`).

##### `backend/src/Http/Controllers/Admin/`
Actions do painel administrativo (backoffice): dashboard de métricas, gestão de produtos e categorias, gestão de pedidos, CRM de clientes, configurações da loja e relatórios.

##### `backend/src/Http/Controllers/POS/`
Actions do Ponto de Venda:
- `SalesRep/` — ações do vendedor de balcão: busca de produto, criação de pré-venda, emissão de ticket.
- `Cashier/` — ações do operador de caixa: abertura de caixa, processamento de pagamento, fechamento de caixa.

##### `backend/src/Http/Controllers/Api/`
Actions da API RESTful (v1), consumida por aplicativos mobile ou integrações B2B. Seguem os princípios REST (verbos HTTP corretos, códigos de status semânticos, respostas JSON padronizadas).

---

### 🎨 `backend/resources/`

Recursos que fazem parte do projeto mas são **processados ou servidos** pela aplicação, não executados como PHP.

#### `backend/resources/locales/`
Arquivos de internacionalização (i18n) no formato padrão (`.json` ou `.po`/`.mo`), organizados por locale:
- `pt-br/` — Português do Brasil (idioma padrão do sistema).
- `en-gb/` — Inglês Britânico (para expansão internacional).
- `es-es/` — Espanhol (para o mercado ibero-americano).

Cada arquivo mapeia uma chave de tradução (`"order.status.paid"`) para a string no idioma correspondente (`"Pagamento Confirmado"`).

#### `backend/resources/views/`
Templates **Twig** (`.twig`). Twig é um motor de templates seguro que separa a apresentação da lógica PHP. Os arquivos seguem a convenção `kebab-case` (ex: `product-card.twig`, `checkout-summary.twig`).

##### `backend/resources/views/components/`
Componentes de design seguindo a metodologia **Atomic Design**, reutilizáveis globalmente por qualquer contexto:
- `atoms/` — os menores blocos indivisíveis: botões (`btn-primary.twig`), campos de input, badges de status, ícones SVG.
- `molecules/` — combinações de átomos que formam um componente com função específica: card de produto, barra de busca, alerta de notificação.
- `organisms/` — combinações de moléculas que formam seções completas de interface: cabeçalho global com navegação, rodapé, tabela de listagem com paginação.

##### `backend/resources/views/layouts/`
Layouts base Twig que definem a estrutura HTML completa de cada contexto visual:
- `base.twig` — layout principal da loja (com head, header, footer e bloco de conteúdo).
- `auth.twig` — layout simplificado para páginas de login e recuperação de senha.
- `error.twig` — layout para páginas de erro (404, 500).

##### `backend/resources/views/storefront/`
Templates específicos da loja virtual. Possuem seus próprios `components/` locais para átomos e moléculas exclusivos do contexto de e-commerce:
- `catalog/` — listagem de produtos, página de categoria, resultados de busca, filtros.
- `checkout/` — carrinho de compras, seleção de endereço, seleção de frete, pagamento, confirmação.
- `customer/` — área do cliente: login, cadastro, histórico de pedidos, edição de perfil.

##### `backend/resources/views/admin/`
Templates do backoffice. Possuem seus próprios `components/` locais para widgets de dashboard e elementos específicos de administração:
- `dashboard/` — painel de KPIs, gráficos de vendas e resumo operacional.
- `catalog/` — formulários e listagens de produtos, categorias e fabricantes.
- `sales/` — listagem e detalhamento de pedidos, emissão de notas fiscais.
- `crm/` — gestão de clientes, aprovação de cadastros, histórico.
- `settings/` — configurações gerais, parâmetros de loja, usuários e permissões.

##### `backend/resources/views/pos/`
Templates do Ponto de Venda, otimizados para uso em telas de toque e operação rápida:
- `cashier/` — interface do operador de caixa: lista de pré-vendas pendentes, processamento de pagamento, fechamento de caixa.
- `sales-rep/` — interface do vendedor: busca de produto por código ou nome, montagem de pré-venda, impressão de ticket.

---

### 🌐 `public_html/`

O **único diretório exposto à internet** pelo servidor web (Apache/Nginx). Nenhum outro diretório deve ser configurado como `DocumentRoot`. Isso garante que código PHP, configurações, segredos e o `vendor/` nunca sejam acessíveis diretamente pelo navegador.

#### `public_html/index.php`
O **Front Controller** — ponto de entrada único de toda a aplicação. Carrega o autoloader do Composer, inicializa o container de DI, monta o pipeline de middlewares e despacha a requisição PSR-7 para o roteador Slim 4. Uma única requisição, independente de qual contexto (Store, Admin, POS, API), começa e termina aqui.

#### `public_html/assets/`
Assets estáticos **já compilados e minificados** pelo pipeline de build (Webpack, Vite ou similar). Servidos diretamente pelo Nginx sem passar pelo PHP:
- `css/` — folhas de estilo compiladas a partir do Sass/PostCSS.
- `js/` — bundles JavaScript otimizados (com tree-shaking e code-splitting).
- `fonts/` — fontes tipográficas auto-hospedadas (WOFF2).

#### `public_html/adm_[PASSWORD]/`
Subdiretório com nome ofuscado que atua como `DocumentRoot` secundário do painel administrativo. A ofuscação do nome (substituindo `[PASSWORD]` por uma string aleatória) é uma medida de segurança por obscuridade que dificulta ataques de força bruta contra a interface de administração. O nome real é definido como variável de ambiente.

---

### 🗄️ `database/`

Versionamento estrutural do banco de dados. Esta pasta **não vai para a produção** na mesma forma que o código da aplicação, mas é essencial para CI/CD e para onboarding de novos desenvolvedores.

#### `database/migrations/`
Scripts SQL ou PHP (usando uma biblioteca de migrations como Phinx ou Doctrine Migrations) que descrevem **cada mudança estrutural** no banco de dados de forma incremental e reversível. Cada arquivo tem um timestamp no nome (`20240801120000_create_customers_table.php`) garantindo ordem de execução determinística. Nunca se altera um arquivo de migration existente — sempre se cria um novo.

#### `database/seeds/`
Scripts de carga inicial de dados, usados para popular o banco em ambientes de desenvolvimento e testes de integração. Por exemplo: categorias padrão, usuário administrador inicial, produtos de demonstração. **Nunca** são executados em produção com dados reais de clientes.

#### `database/schemas/`
Artefatos de modelagem conceitual e relacional: diagramas EER (Enhanced Entity-Relationship) exportados como imagens, arquivos do MySQL Workbench (`.mwb`) ou scripts SQL de criação do schema completo gerados para documentação. Servem como referência visual para a equipe.

---

### 📚 `docs/`

Central unificada de toda a documentação do projeto que não é código. Organizada por tipo de artefato para facilitar a descoberta.

#### `docs/architecture/`
Documentação técnica da arquitetura do sistema.
- `adr/` — **Architecture Decision Records**: documentos curtos e numerados que registram *o quê* foi decidido, *por quê* foi decidido assim e quais alternativas foram descartadas. Exemplo: `ADR-001-escolha-do-slim-4-sobre-laravel.md`.
- `components/` — diagramas de componentes e suas responsabilidades.
- `deployment/` — manuais de deploy, diagramas de infraestrutura (servidores, DNS, SSL), guias de provisionamento.
- `reviews/` — relatórios de revisão de arquitetura e de código, apontando melhorias e débitos técnicos.
- `file_structure_diagram.puml` — o diagrama PlantUML da estrutura de pastas, fonte para geração de imagens renderizadas.

#### `docs/business/`
Documentação orientada ao negócio, escrita em linguagem acessível para stakeholders não técnicos.
- `processes/` — diagramas BPMN ou fluxogramas dos processos de negócio (venda, devolução, compra de fornecedor).
- `use-cases/` — especificações detalhadas de casos de uso do sistema: atores, pré-condições, fluxo principal, fluxos alternativos, fluxos de exceção e pós-condições. Cada arquivo documenta um caso de uso específico.

#### `docs/database/`
Diagramas de entidade-relacionamento (ER/EER) e o dicionário de dados (descrição de cada tabela, coluna, tipo, restrições e significado de negócio).

#### `docs/diagrams/`
Diagramas gerais de múltiplas perspectivas (C4 Model, diagramas de sequência gerais, diagramas de contexto de sistema) destinados tanto à engenharia quanto a stakeholders executivos.

#### `docs/DoD/`
**Definition of Done** — documento que define os critérios objetivos que uma funcionalidade deve satisfazer para ser considerada concluída: testes escritos e passando, cobertura mínima atingida, documentação atualizada, revisão de código aprovada, deploy em staging validado.

#### `docs/domain/`
Glossário e mapa do domínio de negócio.
- `roles/` — descrição de cada papel (ator) que interage com o sistema: Cliente Final, Vendedor de Balcão, Operador de Caixa, Gerente, Administrador do Sistema. Inclui responsabilidades, permissões e jornadas típicas.

#### `docs/issues/`
Centralização de issues e bugs documentados de forma detalhada — especialmente útil para rastrear problemas complexos com contexto técnico e histórico de investigação, complementando (mas não substituindo) o sistema de issues do Git.

#### `docs/kb/`
**Knowledge Base (Base de Conhecimento)** — artigos técnicos sobre decisões, gotchas, tutoriais internos e boas práticas específicas do projeto. É a "wiki interna" da equipe.

#### `docs/legal/`
Documentação legal e de compliance do projeto.
- `labor-opinions/` — laudos técnicos e pareceres jurídicos relacionados ao sistema (ex: parecer sobre conformidade com a LGPD, laudo de auditoria de segurança).

#### `docs/migrations/`
Documentação das migrações de dados complexas — especialmente migrações de dados legados para o novo sistema, detalhando o mapeamento de campos, regras de transformação e plano de rollback.

#### `docs/requirements/`
Especificação de requisitos do sistema.
- `business-rules/` — regras de negócio documentadas de forma estruturada (ex: "desconto máximo por vendedor é 10%", "pedido só pode ser cancelado em até 24h após a confirmação").
- `functional/` — requisitos funcionais: o que o sistema deve *fazer*.
- `non-functional/` — requisitos não funcionais: performance, segurança, disponibilidade, escalabilidade.

#### `docs/specs/`
Especificações formais e machine-readable.
- `features/` — especificações BDD em formato Gherkin (`.feature`), descrevendo comportamentos do sistema em linguagem natural estruturada.
- `schemas/` — schemas JSON Schema, OpenAPI 3.1 (contratos da API REST) e schemas de mensageria (payloads do RabbitMQ).

#### `docs/workflows/`
Diagramas de comportamento dinâmico do sistema.
- `activity-diagrams/` — diagramas de atividade UML que descrevem o fluxo de ações em processos complexos.
- `sequence-diagrams/` — diagramas de sequência UML que mostram a interação temporal entre componentes do sistema.

---

### 🛠️ `scripts/`

Scripts de automação que auxiliam o ciclo de desenvolvimento e operação, mas que **não fazem parte da aplicação em si**.

#### `scripts/devops/`
Scripts de provisionamento de infraestrutura e deploy: configuração de servidor, rotinas de backup de banco de dados, scripts de rollback de deploy e comandos de manutenção emergencial.

#### `scripts/workers/`
Scripts PHP de linha de comando que iniciam os **consumers** do RabbitMQ. Cada worker consome uma fila específica (ex: `process-payment-worker.php`, `send-email-worker.php`) e é gerenciado pelo Supervisor em produção.

---

### 🧪 `tests/`

A suíte completa de testes automatizados. Segue rigorosamente a **pirâmide de testes**: muitos testes unitários rápidos na base, poucos testes E2E lentos no topo.

> [!TIP]
> **Regra de espelhamento:** a estrutura de pastas dentro de `tests/Unit/` e `tests/Integration/` deve **espelhar exatamente** a estrutura de `backend/src/`. Se existe `backend/src/Domain/Customer/Entities/Customer.php`, o teste correspondente é `tests/Unit/Domain/Customer/Entities/CustomerTest.php`.

#### `tests/Unit/`
Testes unitários das regras de domínio e lógica de aplicação. São os testes mais rápidos: **não acessam banco de dados, não fazem chamadas HTTP e não dependem de nenhum serviço externo**. Utilizam Mocks e Stubs para substituir dependências externas. Cada teste deve rodar em menos de 50ms.

#### `tests/Integration/`
Testes de integração que verificam a colaboração entre componentes que dependem de infraestrutura real: os Repositories com um banco de dados de teste real, os Cache Adapters com uma instância Redis de teste, os Mappers com dados SQL reais. São mais lentos que os unitários mas mais rápidos que os funcionais.

#### `tests/Functional/`
Testes funcionais que simulam requisições HTTP completas contra a aplicação (usando um cliente HTTP interno, sem um servidor real). Verificam se as rotas retornam os status codes corretos, se os middlewares se comportam como esperado e se o fluxo de uma requisição completa produz a resposta correta.

#### `tests/E2E/`
Testes ponta a ponta que verificam os fluxos críticos de negócio de forma completa, como um usuário real faria. Podem usar um navegador headless (Playwright, Panther) ou requisições HTTP contra um ambiente de staging. São os mais lentos e caros de executar, reservados para os fluxos de mais alto risco: checkout completo, abertura e fechamento de caixa, emissão de NFC-e.

