# Padrões de Persistência em Rust: Da Teoria de Fowler à Alta Performance
### *Do Active Record e Data Mapper ao Repository e Unit of Work: Como Arquitetar Camadas de Dados Robustas, Resilientes e Idiomáticas no Ecossistema Rust*

> 📌 **Objetivo deste Estudo:**  
> Analisar a convergência entre os clássicos padrões de persistência corporativa (catalogados por Martin Fowler em *Patterns of Enterprise Application Architecture*) e as garantias fundamentais de Rust (*Ownership*, *Borrow Checker*, *Lifetimes*, *Concorrência Segura* e *Zero-Cost Abstractions*). Este documento serve como guia arquitetural e manual de referência para projetar camadas de acesso a dados desacopladas, testáveis e de altíssima performance.

---

## 🧭 Sumário Executivo
1. [O Choque de Paradigmas: Martin Fowler Encontra o Borrow Checker](#1-o-choque-de-paradigmas-martin-fowler-encontra-o-borrow-checker)
2. [A Taxonomia Clássica de Martin Fowler (PoEAA)](#2-a-taxonomia-clássica-de-martin-fowler-poeaa)
3. [Por Que o "Active Record" Clássico é um Anti-Pattern em Rust?](#3-por-que-o-active-record-clássico-é-um-anti-pattern-em-rust)
4. [O Triunfo do "Data Mapper" e a Separação Estrita de Responsabilidades](#4-o-triunfo-do-data-mapper-e-a-separação-estrita-de-responsabilidades)
5. [O Ecossistema Rust: Comparativo Aprofundado (Diesel vs SeaORM vs SQLx)](#5-o-ecossistema-rust-comparativo-aprofundado-diesel-vs-seaorm-vs-sqlx)
6. [O Padrão Repository na Prática: Portas, Adaptadores e Inversão de Dependência](#6-o-padrão-repository-na-prática-portas-adaptadores-e-inversão-de-dependência)
7. [O Padrão Unit of Work & Transações: RAII, Drop Guards e Lifetimes](#7-o-padrão-unit-of-work--transações-raii-drop-guards-e-lifetimes)
8. [Persistência Poliglota em Rust: Quando e Como Diversificar](#8-persistência-poliglota-em-rust-quando-e-como-diversificar)
9. [Implementação Completa Ponta a Ponta (Código Limpo e Compilável)](#9-implementação-completa-ponta-a-ponta-código-limpo-e-compilável)
10. [Matriz de Decisão Arquitetural & Trade-Offs](#10-matriz-de-decisão-arquitetural--trade-offs)
11. [Checklist de Auditoria e Armadilhas Comuns (Gotchas)](#11-checklist-de-auditoria-e-armadilhas-comuns-gotchas)
12. [Referências Bibliográficas](#12-referências-bibliográficas)

---

## 1. O Choque de Paradigmas: Martin Fowler Encontra o Borrow Checker

Quando Martin Fowler publicou sua obra fundamental, *Patterns of Enterprise Application Architecture* (PoEAA) em 2002, o ecossistema corporativo era dominado por linguagens orientadas a objetos com **Garbage Collector** (como Java e C#) e tipagem dinâmica (Smalltalk). 

Nesses ambientes, a construção de ORMs (como Hibernate, Entity Framework e Doctrine) apoiava-se em premissas universais daquela época:
* **Mutabilidade Compartilhada Irrestrita:** Múltiplas partes da aplicação podiam reter ponteiros simultâneos para a mesma instância de entidade na memória.
* **Reflexão Dinâmica em Tempo de Execução:** O framework inspecionava campos privados, lia metadados de anotações e alterava estados internos sem controle estático do compilador.
* **Proxies Ocultos e Bytecode Weaving:** O runtime substituía classes reais por subclasses sintéticas para interceptar chamadas e disparar consultas SQL transparentes (*Lazy Loading*).
* **Identity Maps com Dirty Checking Automático:** Uma sessão global armazenava referências a todas as instâncias em memória e comparava snapshots no final do ciclo para saber o que atualizar.

```
┌────────────────────────────────────────────────────────────────────────┐
│                   O PARADIGMA TRADICIONAL (OOP + GC)                   │
├────────────────────────────────────────────────────────────────────────┤
│  Entidade Compartilhada (Ponteiro A)  ◄───►  Entidade Compartilhada    │
│  Sessão Oculta inspeciona memória via Reflexão                         │
│  Lazy Loading dispara SQL implícito e bloqueante ao invocar getters    │
└────────────────────────────────────────────────────────────────────────┘
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      O PARADIGMA RUST (OWNERSHIP)                      │
├────────────────────────────────────────────────────────────────────────┤
│  Aliasing XOR Mutability: &T (múltiplos leitores) OU &mut T (exclusivo)│
│  Sem Garbage Collector: RAII e escopos determinísticos                 │
│  Sem Reflexão Dinâmica: Verificação estática e Zero-Cost Abstractions  │
│  Operações I/O assíncronas explícitas: Sem mágica bloqueante oculta    │
└────────────────────────────────────────────────────────────────────────┘
```

### O Desafio de Rust
Em Rust, o **Borrow Checker** impõe que uma área de memória nunca pode ter simultaneamente uma referência mutável e outras referências vivas (`Aliasing XOR Mutability`). Além disso:
1. **Não existe reflexão mágica:** O mapeamento deve ser expresso através do sistema de tipos, macros derivativas (`derive`) ou conversões explícitas.
2. **I/O Assíncrono é Cidadão de Primeira Classe:** Em servidores modernos baseados em Tokio, operações de banco são assíncronas (`async/await`). O *Lazy Loading* implícito violaria a previsibilidade do loop de eventos, gerando bloqueios acidentais e deadlocks de pool.
3. **Mover dados é a regra (Move Semantics):** A transferência de posse de structs entre camadas é explícita, tornando padrões estatais complexos como o *Identity Map* antiquados ou contraproducentes no ecossistema Rust.

---

## 2. A Taxonomia Clássica de Martin Fowler (PoEAA)

Fowler catalogou diferentes abordagens para organizar a persistência de dados. Compreender o espectro dessas abordagens é crucial para escolher a ferramenta certa em Rust:

```
Baixo Acoplamento                                          Alto Acoplamento
(Abstração Total)                                      (Centrado no Banco)
◄────────────────────────────────────────────────────────────────────────►
 [Repository]  ───►  [Data Mapper]  ───►  [Active Record]  ───►  [Table Gateway]
 (Interface de       (Mapeador Puro      (Entidade sabe          (Operações SQL
  Coleção DDD)        Memória/Banco)      persistir a si)         diretas)
```

| Padrão de Fowler | Definição Canônica | Viabilidade em Rust |
| :--- | :--- | :--- |
| **Active Record** | Um objeto que envolve uma linha de banco, encapsula acesso ao banco e contém lógica de domínio. | **Anti-Pattern no Core**: Gera acoplamento com o driver e atrito com o borrow checker. Útil apenas em tooling/scripts simples. |
| **Data Mapper** | Uma camada de mapeadores que move dados entre objetos e o banco, mantendo ambos independentes. | **Padrão Ouro**: Structs de domínio puras isoladas de structs de infraestrutura/banco. |
| **Repository** | Medeia entre o domínio e o mapeamento de dados usando uma interface semelhante a uma coleção. | **Essencial**: Implementado via `traits` (Portas) e implementações concretas (Adaptadores). |
| **Unit of Work** | Mantém uma lista de objetos afetados por uma transação de negócio e coordena a escrita atômica. | **Idiomático via RAII**: Encapsulado por transações com *Drop Guards* determinísticos. |
| **Identity Map** | Garante que cada registro seja carregado apenas uma vez, mantendo instâncias em um mapa. | **Raro/Substituído**: Cache explícito (Redis/Moka) ou CQRS substitui a complexidade de ponteiros compartilhados. |

---

## 3. Por Que o "Active Record" Clássico é um Anti-Pattern em Rust?

No padrão Active Record (popularizado por frameworks como Ruby on Rails, Laravel Eloquent e Django ORM), o próprio modelo de negócio possui métodos como `user.save()`, `user.update()` e `User::find(id)`.

Embora extremamente atraente em linguagens dinâmicas para prototipação rápida, **em Rust o Active Record tradicional apresenta falhas estruturais graves**:

### 1. O Dilema do Pool de Conexões e Ciclo de Vida
Para que um método `user.save(&self)` funcione, a struct `User` precisaria:
* **Armazenar uma referência à conexão/pool:** Isso contamina a entidade com lifetimes ou ponteiros compartilhados (`Arc<PgPool>`), poluindo o núcleo do negócio com detalhes de rede e banco de dados.
* **Ou acessar um estado global singleton (`DB_POOL`):** O uso de singletons globais mutáveis ou estáticos em Rust é amplamente desencorajado, prejudicando a testabilidade paralela e violando o princípio da inversão de dependência.

### 2. Violação do Princípio da Responsabilidade Única (SRP)
Uma struct Active Record precisa lidar simultaneamente com:
* Validação de invariantes de negócio (ex: cálculo de idade, regras tributárias).
* Serialização/desserialização de tipos específicos do banco de dados (ex: `VARCHAR`, `TIMESTAMPTZ`, `NUMERIC`).
* Tratamento de falhas de rede, reconexão de pool e commits transacionais.

### 3. Conflito com Modelos de Domínio Ricos (DDD)
Active Record incentiva **Modelos Anêmicos**: todas as colunas da tabela tornam-se campos públicos na struct (`pub name: String`), permitindo mutações externas descontroladas e aniquilando a proteção de invariantes de negócio.

> 💡 **Nota de Engenharia:**  
> O SeaORM possui um conceito chamado `ActiveModel`. Contudo, ele é utilizado estritamente como um **DTO de mutação na camada de infraestrutura**, e não como a entidade rica do domínio da aplicação.

---

## 4. O Triunfo do "Data Mapper" e a Separação Estrita de Responsabilidades

No **Data Mapper**, a camada de domínio permanece 100% pura: as structs de negócio não sabem se os dados são persistidos no PostgreSQL, MongoDB ou em memória. A infraestrutura possui structs próprias para espelhar as tabelas do banco, e um conversor realiza o intercâmbio de dados.

```
┌─────────────────────────────────┐
│     CAMADA DE DOMÍNIO (Pura)    │
│  struct Customer {              │
│      id: CustomerId,            │  ◄── Invariantes garantidas
│      email: Email,              │  ◄── Value Objects blindados
│      balance: Money,            │
│  }                              │
└────────────────┬────────────────┘
                 │
      [ Conversão Explícita ]
       impl From / TryFrom
                 │
┌────────────────▼────────────────┐
│   CAMADA DE INFRAESTRUTURA      │
│  #[derive(sqlx::FromRow)]       │
│  struct CustomerDbRecord {      │
│      id: Uuid,                  │  ◄── Tipos primitivos do banco
│      email: String,             │  ◄── Tipos de drivers (ex: sqlx)
│      balance_cents: i64,        │
│  }                              │
└─────────────────────────────────┘
```

### Vantagens do Data Mapper em Rust:
1. **Compilação Independente:** O módulo de domínio compila em milissegundos sem qualquer dependência pesada de drivers de banco (`sqlx`, `diesel`).
2. **Value Objects Blindados:** O banco armazena `String`, mas o domínio manipula `Email` e `Cpf` que só podem ser instanciados se forem válidos.
3. **Evolução Desacoplada de Esquemas:** O nome de uma coluna no banco pode mudar (ex: `user_mail` para `email_address`) sem que uma única linha da regra de negócio precise ser alterada.

---

## 5. O Ecossistema Rust: Comparativo Aprofundado (Diesel vs SeaORM vs SQLx)

O ecossistema Rust amadureceu significativamente nos últimos anos, oferecendo três principais paradigmas para gerenciar a persistência relacional:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        ESPECTRO DE FERRAMENTAS                         │
├──────────────────────────┬──────────────────────────┬──────────────────┤
│          DIESEL          │          SeaORM          │       SQLx       │
├──────────────────────────┼──────────────────────────┼──────────────────┤
│ • ORM / Data Mapper      │ • Async ORM Moderno      │ • Driver SQL     │
│ • Validação Type-State   │ • Baseado em SQLx        │ • Verificação em │
│ • Síncrono por design    │ • Totalmente Assíncrono  │   Tempo de       │
│   (async via extensão)   │ • Migrações & CLI        │   Compilação     │
│ • Zero Runtime Overhead  │ • Ergonômico e Fluente   │ • Zero Mágica    │
└──────────────────────────┴──────────────────────────┴──────────────────┘
```

### 1. Diesel: A Fortaleza dos Tipos em Tempo de Compilação
O Diesel é o pioneiro dos ORMs em Rust. Sua principal proposta é utilizar o poderoso sistema de tipos da linguagem para impedir erros SQL antes mesmo da execução:
* **Verificação via AST de Tipos:** Se você tentar inserir uma `String` em uma coluna inteira ou referenciar uma tabela inexistente, o código não compilará.
* **Sem dependência de banco em runtime de compilação:** O schema é gerado a partir de arquivos `.sql` e expresso no código como macros (`table!`).
* **Performance Imbatível:** Como todas as queries são monomorfizadas em código de máquina otimizado, o overhead sobre o driver nativo é praticamente nulo.
* **Trade-off:** Mensagens de erro de compilação podem ser extremamente densas quando ocorrem falhas em tipos complexos, e a experiência assíncrona exige o uso do crate complementar `diesel-async`.

### 2. SeaORM: A Ergonomia de ORMs Modernos no Mundo Assíncrono
O SeaORM surgiu para suprir a demanda por um ORM assíncrono moderno e completo para a web em Rust:
* **Construído sobre o SQLx:** Herda a robustez do pool de conexões assíncronas do SQLx.
* **Divisão Clara de Papéis:** Separa rigidamente `Entity` (metadados), `Model` (leitura imutável) e `ActiveModel` (mutações parciais e inserções).
* **Tooling Completo:** Gera entidades automaticamente a partir de bancos existentes (`sea-orm-cli generate entity`) e provê controle de migrações estruturado.
* **Trade-off:** Adiciona uma camada de abstração em torno do SQL, o que pode mascarar queries subótimas e introduzir leve custo de serialização comparado a consultas diretas.

### 3. SQLx: O Controle Absoluto com SQL Puro Tipado
O SQLx recusa a premissa de um ORM tradicional e foca em ser o melhor driver SQL possível:
* **Macro `query!` com Verificação Real:** O compilador conecta-se a um banco de dados real (ou lê o cache `sqlx-data.json`) durante o build para validar que a query SQL é válida e que os tipos das colunas batem com as structs Rust.
* **Transparência Total:** Você escreve SQL puro e otimizado, aproveitando todos os recursos nativos do PostgreSQL (Window Functions, CTEs, JSONB, PostGIS) sem limitações de DSLs proprietárias.
* **Ideal para Arquitetura Limpa:** O desenvolvedor projeta repositórios manuais limpos, mapeando exatamente o que o caso de uso necessita.
* **Trade-off:** Exige escrita manual de queries de CRUD básico e requer manutenção do arquivo de cache para pipelines de CI/CD sem banco ativo.

---

## 6. O Padrão Repository na Prática: Portas, Adaptadores e Inversão de Dependência

Na Arquitetura Hexagonal (Ports & Adapters) e na Clean Architecture, o **Repository** é a personificação do **Princípio da Inversão de Dependência (DIP)**:
* **A Porta:** Uma `trait` definida na camada de Domínio, expressa na Linguagem Ubíqua do negócio.
* **O Adaptador:** Uma `struct` definida na camada de Infraestrutura, responsável por traduzir as chamadas da trait em queries SQL ou comandos de rede.

```
                      CAMADA DE DOMÍNIO
                  ┌───────────────────────┐
                  │   trait UserRepository │  ◄── Porta (Interface)
                  └───────────▲───────────┘
                              │
                    Inversão de Dependência
                              │
                  ┌───────────┴───────────┐
                  │ PostgresUserRepository│  ◄── Adaptador (Infra)
                  └───────────────────────┘
                   CAMADA DE INFRAESTRUTURA
```

### O Desafio Assíncrono em Traits Rust
Historicamente, Rust não permitia métodos `async fn` em `traits`. A solução padrão da comunidade era utilizar o macro `#[async_trait]`, que envelopa o retorno em um `Pin<Box<dyn Future>>` alocado na Heap.

A partir do **Rust 1.75**, o suporte nativo a **AFIT (Async Fn in Trait)** foi introduzido na linguagem. No entanto, quando necessitamos de **Despacho Dinâmico** (`dyn Trait`) para injeção de dependência flexível em containers ou testes com mocks, o `#[async_trait]` continua sendo a solução mais estável e ergonômica.

### Despacho Estático vs Despacho Dinâmico

| Abordagem | Sintaxe | Vantagens | Desvantagens |
| :--- | :--- | :--- | :--- |
| **Estático (Generics)** | `struct UseCase<R: UserRepository> { repo: R }` | Zero overhead de chamada (*monomorphization*), inline pelo compilador. | Pode aumentar o tamanho do binário e complexificar assinaturas de construtores. |
| **Dinâmico (Trait Objects)** | `struct UseCase { repo: Arc<dyn UserRepository> }` | Flexível, permite composição em tempo de execução e fácil substituição por mocks. | Pequeno overhead de tabela virtual (*vtable*) e alocação atômica (`Arc`). |

---

## 7. O Padrão Unit of Work & Transações: RAII, Drop Guards e Lifetimes

Martin Fowler definiu a **Unit of Work** como o componente que rastreia tudo o que você fez durante uma transação comercial que pode afetar o banco de dados e coordena a gravação dessas mudanças.

Em ecossistemas orientados a objetos, a Unit of Work normalmente mantém listas de entidades (`new`, `dirty`, `deleted`) e compara snapshots na memória. 

### O Modo Idiomático de Rust: RAII e Drop Guards
Em Rust, a segurança transacional é implementada com elegância através do padrão **RAII (Resource Acquisition Is Initialization)** e o mecanismo de **Drop**:

```rust
// Ao abrir a transação, obtemos a posse exclusiva da estrutura Transaction
let mut tx = pool.begin().await?;

// Executamos operações sobre a transação
user_repo.save_transactional(&mut tx, &user).await?;
audit_repo.log_transactional(&mut tx, "USER_CREATED").await?;

// Se qualquer operação acima falhar com o operador '?',
// a variável 'tx' sai de escopo e seu trait Drop é executado,
// disparando AUTOMATICAMENTE um ROLLBACK na conexão!

// O commit deve ser EXPLICÍCITO consumindo a posse de 'tx':
tx.commit().await?;
```

> 🛡️ **Segurança Arquitetural:**  
> Não existe risco de esquecer uma transação aberta ou travar o pool de conexões por exceções não capturadas. O próprio compilador e o runtime determinístico garantem que o rollback ocorrerá se o fluxo for interrompido antes do commit.

---

## 8. Persistência Poliglota em Rust: Quando e Como Diversificar

O princípio da **Persistência Poliglota**, defendido por Martin Fowler, postula que qualquer aplicação corporativa de médio ou grande porte deve armazenar seus dados utilizando diferentes motores de persistência, de acordo com as características naturais de acesso de cada conjunto de dados:

```
                              ┌──────────────────────────────────┐
                              │     APLICAÇÃO BACKEND RUST       │
                              └─┬──────────────┬───────────────┬─┘
                                │              │               │
        ┌───────────────────────┘              │               └───────────────────────┐
        ▼                                      ▼                                       ▼
┌───────────────────┐                ┌───────────────────┐                   ┌───────────────────┐
│     POSTGRESQL    │                │       REDIS       │                   │      MONGODB      │
│ (sqlx / diesel)   │                │    (redis-rs)     │                   │     (mongodb)     │
│ Dados Transacionais│               │ Sessões, Caches,  │                   │ Documentos BSON,  │
│ e Integridade ACID│                │ Rate Limits       │                   │ Logs e Eventos    │
└───────────────────┘                └───────────────────┘                   └───────────────────┘
```

### O Arsenal Poliglota no Ecossistema Rust:

1. **Relacional Transacional (PostgreSQL / MySQL / SQLite):**
   * **Crates:** `sqlx`, `diesel`, `sea-orm`, `rusqlite`.
   * **Uso:** Regras contábeis, estoques, pagamentos, cadastros com restrições relacionais rígidas.
2. **Chave-Valor e In-Memory (Redis):**
   * **Crate:** `redis` (com suporte assíncrono via `deadpool-redis` ou conexões multiplexadas tokio).
   * **Uso:** Cache L2, controle de idempotência, bloqueios distribuídos (Redlock) e sessões voláteis.
3. **Documentos Flexíveis (MongoDB):**
   * **Crate:** `mongodb`.
   * **Integração:** Totalmente alinhado com o crate `serde`. A conversão de structs ricas de Rust para documentos BSON ocorre em nível de compilação com zero overhead.
4. **Grafos e Relações Complexas (Neo4j):**
   * **Crate:** `neo4rs`.
   * **Uso:** Redes sociais internas, motores de recomendação de produtos, detecção de fraudes em pagamentos através de consultas Cypher assíncronas.
5. **Analytics e Séries Temporais (ClickHouse / TimescaleDB):**
   * **Crates:** `clickhouse-rs`, `sqlx` (com extensão Timescale).
   * **Uso:** Telemetria, logs de auditoria imutáveis, métricas de tráfego de alta ingestão.
6. **Armazenamento Embutido de Altíssima Velocidade (Embedded Key-Value):**
   * **Crates:** `rocksdb`, `sled`.
   * **Uso:** Armazenamento local para aplicações de borda (Edge), processamento offline ou caches ultrarrápidos persistidos em SSD NVMe.

---

## 9. Implementação Completa Ponta a Ponta (Código Limpo e Compilável)

Abaixo apresentamos uma implementação arquitetural completa, demonstrando como desacoplar a regra de negócio do motor de persistência em Rust:

### 1. Camada de Domínio: Entidade, Value Object e Contrato (Porta)

```rust
// domain/mod.rs
use async_trait::async_trait;
use std::fmt;

// --- Erro de Domínio Tipado ---
#[derive(Debug, PartialEq, Eq)]
pub enum DomainError {
    InvalidEmail(String),
    UserNotFound(uuid::Uuid),
    EmailAlreadyExists(String),
    InfrastructureFailure(String),
}

impl fmt::Display for DomainError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidEmail(msg) => write!(f, "Email inválido: {msg}"),
            Self::UserNotFound(id) => write!(f, "Usuário não encontrado: {id}"),
            Self::EmailAlreadyExists(email) => write!(f, "Email já cadastrado: {email}"),
            Self::InfrastructureFailure(err) => write!(f, "Falha de persistência: {err}"),
        }
    }
}

impl std::error::Error for DomainError {}

// --- Value Object: Email Imutável e Validado ---
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Email(String);

impl Email {
    pub fn new(raw: &str) -> Result<Self, DomainError> {
        let trimmed = raw.trim();
        if trimmed.contains('@') && trimmed.contains('.') && trimmed.len() >= 5 {
            Ok(Self(trimmed.to_lowercase()))
        } else {
            Err(DomainError::InvalidEmail(raw.to_string()))
        }
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

// --- Entidade de Domínio Pura ---
#[derive(Debug, Clone)]
pub struct User {
    id: uuid::Uuid,
    name: String,
    email: Email,
    active: bool,
}

impl User {
    pub fn create(name: String, email: Email) -> Self {
        Self {
            id: uuid::Uuid::new_v4(),
            name,
            email,
            active: true,
        }
    }

    // Reconstituição de persistência (sem gerar novo ID)
    pub fn reconstitute(id: uuid::Uuid, name: String, email: Email, active: bool) -> Self {
        Self { id, name, email, active }
    }

    pub fn id(&self) -> uuid::Uuid { self.id }
    pub fn name(&self) -> &str { &self.name }
    pub fn email(&self) -> &Email { &self.email }
    pub fn is_active(&self) -> bool { self.active }

    pub fn deactivate(&mut self) {
        self.active = false;
    }
}

// --- Porta do Repositório (Trait) ---
#[async_trait]
pub trait UserRepository: Send + Sync {
    async fn find_by_id(&self, id: uuid::Uuid) -> Result<Option<User>, DomainError>;
    async fn find_by_email(&self, email: &Email) -> Result<Option<User>, DomainError>;
    async fn save(&self, user: &User) -> Result<(), DomainError>;
    async fn update(&self, user: &User) -> Result<(), DomainError>;
}
```

---

### 2. Camada de Infraestrutura: Adaptador SQLx Concreto (Data Mapper)

```rust
// infrastructure/postgres_user_repo.rs
use crate::domain::{DomainError, Email, User, UserRepository};
use async_trait::async_trait;
use sqlx::PgPool;

pub struct PostgresUserRepository {
    pool: PgPool,
}

impl PostgresUserRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

// Struct plana para mapeamento direto da linha da tabela (Data Mapper Record)
#[derive(sqlx::FromRow)]
struct UserDbRow {
    id: uuid::Uuid,
    name: String,
    email: String,
    active: bool,
}

impl TryFrom<UserDbRow> for User {
    type Error = DomainError;

    fn try_from(row: UserDbRow) -> Result<Self, Self::Error> {
        let email = Email::new(&row.email)?;
        Ok(User::reconstitute(row.id, row.name, email, row.active))
    }
}

#[async_trait]
impl UserRepository for PostgresUserRepository {
    async fn find_by_id(&self, id: uuid::Uuid) -> Result<Option<User>, DomainError> {
        let row_opt = sqlx::query_as::<_, UserDbRow>(
            "SELECT id, name, email, active FROM users WHERE id = $1"
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| DomainError::InfrastructureFailure(e.to_string()))?;

        match row_opt {
            Some(row) => Ok(Some(row.try_into()?)),
            None => Ok(None),
        }
    }

    async fn find_by_email(&self, email: &Email) -> Result<Option<User>, DomainError> {
        let row_opt = sqlx::query_as::<_, UserDbRow>(
            "SELECT id, name, email, active FROM users WHERE email = $1"
        )
        .bind(email.as_str())
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| DomainError::InfrastructureFailure(e.to_string()))?;

        match row_opt {
            Some(row) => Ok(Some(row.try_into()?)),
            None => Ok(None),
        }
    }

    async fn save(&self, user: &User) -> Result<(), DomainError> {
        sqlx::query(
            "INSERT INTO users (id, name, email, active) VALUES ($1, $2, $3, $4)"
        )
        .bind(user.id())
        .bind(user.name())
        .bind(user.email().as_str())
        .bind(user.is_active())
        .execute(&self.pool)
        .await
        .map_err(|e| DomainError::InfrastructureFailure(e.to_string()))?;

        Ok(())
    }

    async fn update(&self, user: &User) -> Result<(), DomainError> {
        sqlx::query(
            "UPDATE users SET name = $1, email = $2, active = $3 WHERE id = $4"
        )
        .bind(user.name())
        .bind(user.email().as_str())
        .bind(user.is_active())
        .bind(user.id())
        .execute(&self.pool)
        .await
        .map_err(|e| DomainError::InfrastructureFailure(e.to_string()))?;

        Ok(())
    }
}
```

---

### 3. Camada de Testes: Adaptador In-Memory (Test Double / Mock)

Graças ao desacoplamento da trait, podemos testar regras de negócio sem subir contêineres Docker nem criar instâncias de bancos de dados:

```rust
// tests/mocks/in_memory_user_repo.rs
use crate::domain::{DomainError, Email, User, UserRepository};
use async_trait::async_trait;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

#[derive(Default, Clone)]
pub struct InMemoryUserRepository {
    // Armazenamento concorrente seguro para testes assíncronos
    storage: Arc<RwLock<HashMap<uuid::Uuid, User>>>,
}

impl InMemoryUserRepository {
    pub fn new() -> Self {
        Self::default()
    }
}

#[async_trait]
impl UserRepository for InMemoryUserRepository {
    async fn find_by_id(&self, id: uuid::Uuid) -> Result<Option<User>, DomainError> {
        let lock = self.storage.read().await;
        Ok(lock.get(&id).cloned())
    }

    async fn find_by_email(&self, email: &Email) -> Result<Option<User>, DomainError> {
        let lock = self.storage.read().await;
        let found = lock.values().find(|u| u.email() == email).cloned();
        Ok(found)
    }

    async fn save(&self, user: &User) -> Result<(), DomainError> {
        let mut lock = self.storage.write().await;
        lock.insert(user.id(), user.clone());
        Ok(())
    }

    async fn update(&self, user: &User) -> Result<(), DomainError> {
        let mut lock = self.storage.write().await;
        if lock.contains_key(&user.id()) {
            lock.insert(user.id(), user.clone());
            Ok(())
        } else {
            Err(DomainError::UserNotFound(user.id()))
        }
    }
}
```

---

### 4. Camada de Aplicação: Caso de Uso Orquestrador

```rust
// application/register_user.rs
use crate::domain::{DomainError, Email, User, UserRepository};
use std::sync::Arc;

pub struct RegisterUserInput {
    pub name: String,
    pub email: String,
}

pub struct RegisterUserUseCase {
    repo: Arc<dyn UserRepository>,
}

impl RegisterUserUseCase {
    pub fn new(repo: Arc<dyn UserRepository>) -> Self {
        Self { repo }
    }

    pub async fn execute(&self, input: RegisterUserInput) -> Result<uuid::Uuid, DomainError> {
        let email = Email::new(&input.email)?;

        // Garantir invariante de unicidade
        if self.repo.find_by_email(&email).await?.is_some() {
            return Err(DomainError::EmailAlreadyExists(input.email));
        }

        let user = User::create(input.name, email);
        let user_id = user.id();

        self.repo.save(&user).await?;

        Ok(user_id)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::tests::mocks::InMemoryUserRepository;

    #[tokio::test]
    async fn deve_cadastrar_usuario_com_sucesso() {
        let repo = Arc::new(InMemoryUserRepository::new());
        let use_case = RegisterUserUseCase::new(repo);

        let input = RegisterUserInput {
            name: "Dev Rust".into(),
            email: "rustacean@ferris.rs".into(),
        };

        let result = use_case.execute(input).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn nao_deve_permitir_emails_duplicados() {
        let repo = Arc::new(InMemoryUserRepository::new());
        let use_case = RegisterUserUseCase::new(repo);

        let input1 = RegisterUserInput {
            name: "Primeiro".into(),
            email: "duplicado@exemplo.com".into(),
        };
        let input2 = RegisterUserInput {
            name: "Segundo".into(),
            email: "duplicado@exemplo.com".into(),
        };

        assert!(use_case.execute(input1).await.is_ok());
        let err = use_case.execute(input2).await.unwrap_err();
        assert_eq!(err, DomainError::EmailAlreadyExists("duplicado@exemplo.com".into()));
    }
}
```

---

## 10. Matriz de Decisão Arquitetural & Trade-Offs

Escolher o motor ou padrão de persistência correto depende das restrições e objetivos do seu projeto:

```
                      QUAL ESTRATÉGIA ESCOLHER?
                                  │
                  ┌───────────────┴───────────────┐
                  ▼                               ▼
       Precisa de Relacional?           Não Relacional / Alta Vazão
                  │                               │
        ┌─────────┴─────────┐                     ├── Cache / Sessão ────► Redis
        ▼                   ▼                     ├── Schemas Livres ────► MongoDB
  Controle Fino       Produtividade               ├── Grafos/Redes   ────► Neo4j
  e SQL Nativo         e Mapeamento               └── Métricas / IoT ────► ClickHouse
        │                   │
        ▼                   ▼
      SQLx                SeaORM
 (DDD / Clean Arch)    (Aplicações Web Rápidas)
        │
   Quer Type-State sem
   Banco no CI? ──► DIESEL
```

| Critério de Comparação | SQLx Puro | SeaORM | Diesel | Rusqlite (SQLite) |
| :--- | :--- | :--- | :--- | :--- |
| **Padrão Fowler** | Data Mapper Manual / Gateway | Data Mapper Fluente | Data Mapper / Query Builder | Gateway Direto |
| **Verificação SQL** | Tempo de Compilação (com banco/cache) | Runtime / Metadados estáticos | Tempo de Compilação (AST Rust pura) | Runtime puro |
| **Suporte Assíncrono** | Nativo (Tokio / async-std) | Nativo (via SQLx) | Extensão (`diesel-async`) | Não (Síncrono nativo) |
| **Controle de Queries** | Absoluto (SQL Nativo) | Alto (Abstraído) | Médio (DSL Tipada) | Absoluto (SQL Nativo) |
| **Aderência a DDD** | Excelente (Zero poluição) | Boa (Exige mapear `ActiveModel`) | Excelente | Boa |
| **Curva de Aprendizado** | Baixa (basta saber SQL) | Média (Conceitos de ORM) | Alta (Tipagem avançada) | Baixa |
| **Cenário Recomendado** | Microsserviços e Arquitetura Limpa | APIs REST corporativas padrão | Sistemas Críticos de Baixa Latência | CLIs, Desktop e Edge Computing |

---

## 11. Checklist de Auditoria e Armadilhas Comuns (Gotchas)

Ao projetar ou revisar a camada de dados em Rust, certifique-se de evitar os erros clássicos:

### ⚠️ Armadilha 1: O Problema N+1 em Consultas Assíncronas
Sem o *Lazy Loading* implícito de ORMs dinâmicos, o perigo de N+1 ocorre quando desenvolvedores executam loops imperativos com `await` interno:
* ❌ **Incorreto:** Iterar sobre 1.000 pedidos e, para cada um, disparar `client_repo.find_by_id(order.client_id).await?`. Isso gera 1.001 viagens de rede (*round-trips*).
* ✅ **Correto:** Escrever um `JOIN` explícito na query SQL ou utilizar uma consulta de lote: `SELECT * FROM clients WHERE id = ANY($1)`.

### ⚠️ Armadilha 2: Manter Transações Abertas Durante Chamadas HTTP
* ❌ **Incorreto:** Abrir uma transação no banco, fazer uma requisição HTTP para um gateway externo (como Stripe ou Mercado Pago) e depois realizar o commit. Se o gateway demorar 5 segundos, uma conexão preciosa do pool fica bloqueada, esgotando os recursos do servidor sob carga.
* ✅ **Correto:** Execute operações de rede fora da transação. Abra a transação apenas para persistir as alterações atômicas no banco local.

### ⚠️ Armadilha 3: Poluição de Tipos do Domínio com Crates Externos
* ❌ **Incorreto:** Colocar `#[derive(sqlx::FromRow)]` ou `#[diesel(table_name = users)]` diretamente na entidade de domínio `Customer`.
* ✅ **Correto:** O domínio deve depender exclusivamente de Rust padrão (e tipos universais como `uuid` ou `chrono` se indispensável). Mantenha as anotações nas structs da camada de infraestrutura.

### ⚠️ Armadilha 4: Vazamento de Erros de Infraestrutura
* ❌ **Incorreto:** Deixar assinaturas de use cases retornarem `Result<T, sqlx::Error>`. Se você migrar para Mongo ou Redis, quebrará toda a camada de aplicação.
* ✅ **Correto:** Mapeie erros de banco para enums de domínio (`DomainError::InfrastructureFailure` ou `DomainError::UserNotFound`).

### 📋 Checklist de Conformidade da Persistência
- [ ] O domínio possui apenas entidades ricas e Value Objects com invariantes protegidas?
- [ ] Nenhuma struct do domínio possui anotações de tabelas ou dependências diretas de drivers de banco?
- [ ] Todos os repositórios são expostos na forma de `traits` para permitir inversão de dependência?
- [ ] Mocks em memória (`InMemoryRepository`) foram construídos para permitir testes unitários sem Docker?
- [ ] As transações utilizam escopos determinísticos (RAII) com `commit()` explícito e rollback por drop?
- [ ] As queries em lote evitam o problema clássico de N+1?
- [ ] Erros de infraestrutura são sanitizados e mapeados para erros controlados do domínio?

---

## 12. Referências Bibliográficas

1. **FOWLER, Martin.** *Patterns of Enterprise Application Architecture (PoEAA)*. Boston: Addison-Wesley, 2002.
2. **EVANS, Eric.** *Domain-Driven Design: Tackling Complexity in the Heart of Software*. Boston: Addison-Wesley, 2003.
3. **MARTIN, Robert C.** *Clean Architecture: A Craftsman's Guide to Software Structure and Design*. Prentice Hall, 2017.
4. **KLABNIK, Steve; NICHOLS, Carol.** *The Rust Programming Language*. San Francisco: No Starch Press, 2023.
5. **SQLx Contributors.** *SQLx: The Rust SQL Toolkit*. Documentação Oficial: <https://github.com/launchbadge/sqlx>.
6. **Diesel Core Team.** *Diesel: A Safe, Extensible ORM and Query Builder for Rust*. Documentação Oficial: <https://diesel.rs>.
7. **SeaQL Team.** *SeaORM: An Async & Dynamic ORM for Rust*. Documentação Oficial: <https://www.sea-ql.org/SeaORM>.
