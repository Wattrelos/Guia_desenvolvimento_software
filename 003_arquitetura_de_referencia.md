# Guia Mestre de Arquitetura de Software: O Padrão de Referência Universal
### *Clean Architecture, Domain-Driven Design (DDD), Ports & Adapters e ADR para Qualquer Projeto Moderno*

> 📌 **Objetivo deste Guia:**  
> Servir como manual de referência definitiva e atemporal para guiar o desenho, a organização e o desenvolvimento de **qualquer sistema de software futuro** (seja em PHP, Java, TypeScript, C# ou Go). Ele documenta como estruturar sistemas que resistem ao teste do tempo, imunes a mudanças de frameworks, bancos de dados ou interfaces.

---

## 🧭 Sumário Executivo
1. [O Manifesto: Por Que Adotar Esta Arquitetura?](#1-o-manifesto-por-que-adotar-esta-arquitetura)
2. [O Mapa das 4 Camadas Concêntricas](#2-o-mapa-das-4-camadas-concêntricas)
3. [Camada 1: O Núcleo do Domínio (Pure DDD)](#3-camada-1-o-núcleo-do-domínio-pure-ddd)
4. [Camada 2: Casos de Uso da Aplicação (Application Layer)](#4-camada-2-casos-de-uso-da-aplicação-application-layer)
5. [Camada 3: Infraestrutura e Adaptadores Externos (Infrastructure Layer)](#5-camada-3-infraestrutura-e-adaptadores-externos-infrastructure-layer)
6. [Camada 4: Apresentação e Entrega (ADR Pattern)](#6-camada-4-apresentação-e-entrega-adr-pattern)
7. [Inversão de Dependência (DIP): O Segredo do Baixo Acoplamento](#7-inversão-de-dependência-dip-o-segredo-do-baixo-acoplamento)
8. [Passo a Passo: Como Criar uma Nova Feature do Zero Sem Errar](#8-passo-a-passo-como-criar-uma-nova-feature-do-zero-sem-errar)
9. [Exemplo de Código Ponta a Ponta (Implementação Real)](#9-exemplo-de-código-ponta-a-ponta-implementação-real)
10. [Checklist de Auditoria: Como Saber se Você Violou a Arquitetura](#10-checklist-de-auditoria-como-saber-se-você-violou-a-arquitetura)

---

## 1. O Manifesto: Por Que Adotar Esta Arquitetura?

No desenvolvimento amador, o software é construído em volta do **Banco de Dados** ou do **Framework**:
- Cria-se a tabela no MySQL ➔ Gera-se o modelo ➔ Cria-se um Controller gigante com queries SQL e regras misturadas.

Essa abordagem cobra um preço altíssimo quando o projeto cresce:
- Testar o código exige subir bancos de dados lentos e instáveis.
- Trocar de framework (ex: migrar de Slim para Laravel, ou de Spring para Quarkus) significa reescrever 90% da aplicação.
- Uma alteração em uma regra de cálculo de frete quebra uma tela do painel administrativo.

### O Princípio da Arquitetura Limpa
> **"Frameworks, bancos de dados, filas e protocolos de rede são detalhes de implementação. O coração do teu software é a regra de negócio."**

```
┌────────────────────────────────────────────────────────────────────────┐
│                   A PROMESSA DA ARQUITETURA LIMPA                     │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Independência de Frameworks: O negócio não depende de bibliotecas.  │
│ 2. Testabilidade Total: 100% das regras testáveis sem banco de dados.  │
│ 3. Independência de UI: O mesmo checkout roda na Web, App e PDV.       │
│ 4. Independência de Banco: O MySQL pode virar PostgreSQL ou MongoDB.   │
│ 5. Independência de Agentes Externos: APIs de pagamento são plugáveis. │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. O Mapa das 4 Camadas Concêntricas

A arquitetura organiza-se em círculos concêntricos governados por uma única regra estrita: **A Regra da Dependência**.

> [!IMPORTANT]
> **A Regra da Dependência:**  
> O código de uma camada interna **NUNCA** pode importar, conhecer ou fazer menção a classes, bibliotecas ou conceitos de uma camada externa.

```
┌─────────────────────────────────────────────────────────────────────────┐
│ 4. APRESENTAÇÃO / ENTREGA (Http, Middlewares, Responders, CLI, Twig)    │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │ 3. INFRAESTRUTURA (PDO, MySQL, Redis, RabbitMQ, Stripe, Mappers)│   │
│   │   ┌─────────────────────────────────────────────────────────┐   │   │
│   │   │ 2. APLICAÇÃO (Casos de Uso, DTOs de Entrada e Saída)    │   │   │
│   │   │   ┌─────────────────────────────────────────────────┐   │   │   │
│   │   │   │ 1. DOMÍNIO PURO (Entidades, Value Objects,      │   │   │   │
│   │   │   │    Eventos de Domínio, Contratos de Repositório)│   │   │   │
│   │   │   └─────────────────────────────────────────────────┘   │   │   │
│   │   └─────────────────────────────────────────────────────────┘   │   │
│   └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                   ▲
               O fluxo de dependência aponta APENAS para dentro!
```

---

## 3. Camada 1: O Núcleo do Domínio (Pure DDD)

Localização: `src/Domain/` (ou `src/main/java/.../domain/`)

Esta é a camada mais nobre do software. Ela contém as **regras fundamentais do negócio** e deve ser escrita em PHP/Java puro, sem herdar de classes de frameworks nem conter anotações de ORM complexas.

### O Que Vive no Domínio:

1. **Entidades (Entities):**
   - Objetos que possuem uma identidade contínua ao longo do tempo.
   - *Exemplo:* Um `Pedido` com código `PED-1029`. Mesmo que mude de status (de "Pendente" para "Pago"), ele continua sendo o mesmo pedido.
   - **Regra:** As entidades devem proteger suas próprias regras e invariantes (ex: não permitir que um pedido seja pago duas vezes).

2. **Objetos de Valor (Value Objects - VOs):**
   - Objetos imutáveis que não possuem ID e são definidos exclusivamente pelo seu valor.
   - *Exemplos:* `Email`, `CpfCnpj`, `Money`, `Cep`, `Dimensao`.
   - **Vantagem:** Evita o vício da "Obsessão Primitiva" (passar strings e inteiros soltos). Um `Cpf` já se auto-valida no construtor; se o objeto existe, você tem 100% de certeza de que o CPF é válido.

3. **Agregados (Aggregate Roots):**
   - Um conjunto coeso de entidades tratadas como uma fortaleza transacional.
   - *Exemplo:* O agregado `Order` contém a coleção de `OrderItem`. Ninguém de fora pode manipular um `OrderItem` diretamente sem passar pela raiz `Order`.

4. **Eventos de Domínio (Domain Events):**
   - Registros de fatos importantes que já aconteceram no negócio.
   - *Exemplos:* `OrderPlacedEvent`, `CustomerRegisteredEvent`, `StockDepletedEvent`.

5. **Contratos de Repositório (Interfaces):**
   - A declaração de como o domínio quer salvar e recuperar seus dados.
   - *Exemplo:* `interface OrderRepositoryInterface { public function save(Order $order): void; }`.

> [!CAUTION]
> **O Que NUNCA Deve Entrar no Domínio:**  
> Queries SQL, comandos cURL, chamadas ao Redis, referências a HTTP (Requests, Sessions, Cookies) ou classes de bibliotecas externas.

---

## 4. Camada 2: Casos de Uso da Aplicação (Application Layer)

Localização: `src/Application/`

A camada de aplicação orquestra os fluxos do sistema. Ela responde a comandos do usuário e traduz intenções em ações de negócio.

### Componentes Chave:

1. **Casos de Uso (Use Cases / Interactors):**
   - Cada caso de uso representa **uma única ação do sistema** (Princípio SRP).
   - *Exemplos:* `ProcessCheckoutUseCase`, `RegisterCustomerUseCase`, `CancelOrderUseCase`.
   - Um Use Case recebe dados, consulta repositórios, aciona métodos nas entidades, persiste alterações e despacha eventos.

2. **DTOs (Data Transfer Objects):**
   - Objetos simples sem regras de negócio, usados apenas para carregar dados através das fronteiras.
   - **Input DTO:** Converte o payload vindo da Web/API em tipos primitivos limpos.
   - **Output DTO:** Dados formatados retornados para quem chamou o caso de uso.

3. **Contrato de Transação (Unit of Work Interface):**
   - Interface que permite ao Caso de Uso abrir e fechar transações ACID sem saber qual banco de dados está sendo utilizado.

---

## 5. Camada 3: Infraestrutura e Adaptadores Externos (Infrastructure Layer)

Localização: `src/Infrastructure/`

A infraestrutura é o "mundo sujo" da tecnologia. É onde o código conversa com discos, placas de rede, bancos relacionais e APIs de terceiros.

```
Infrastructure/
├── Persistence/          # Acesso a Dados
│   ├── Connection/       # Gerenciador PDO / Drivers de Banco
│   ├── QueryBuilder/     # Construtores de SQL seguro
│   ├── Mappers/          # Tradutores: Colunas do BD ⇄ Entidades do Domínio
│   └── Repositories/     # Implementações concretas das interfaces do Domínio
├── Cache/                # Drivers de Redis / Memcached
├── Messaging/            # Publicadores de fila (RabbitMQ, Kafka)
├── Security/             # Criptografia, Tokens JWT, Hasher Argon2id
└── Gateways/             # Clientes de APIs externas (Stripe, Correios, SEFAZ)
```

> [!TIP]
> **O Poder do Data Mapper:**  
> O `DataMapper` isola o esquema do teu banco de dados das classes de negócio. Se no banco a coluna se chama `cli_cd_status_v1`, no teu código de domínio a entidade terá uma propriedade limpa e expressiva como `status: CustomerStatus`. O Mapper faz a tradução bidirecional invisível.

---

## 6. Camada 4: Apresentação e Entrega (ADR Pattern)

Localização: `src/Http/` (ou `src/Presentation/`)

Para projetos modernos, o padrão **ADR (Action-Domain-Responder)** supera o MVC tradicional. Ele divide a responsabilidade em três papéis cristalinos:

```
                  ┌──────────────────────────────────────────────┐
                  │                 REQUISIÇÃO                   │
                  └──────────────────────┬───────────────────────┘
                                         ▼
                 ┌────────────────────────────────────────────────┐
                 │ ACTION (Controller Fino / Skinny Action)       │
                 │ 1. Extrai dados do HTTP Request                │
                 │ 2. Instancia o InputDTO                        │
                 │ 3. Executa o Caso de Uso                       │
                 └──────────────────────┬─────────────────────────┘
                                        ▼
                 ┌────────────────────────────────────────────────┐
                 │ DOMAIN (Caso de Uso da Aplicação)              │
                 │ Executa todas as regras de negócio e devolve   │
                 │ o OutputDTO para a Action                      │
                 └──────────────────────┬─────────────────────────┘
                                        ▼
                 ┌────────────────────────────────────────────────┐
                 │ RESPONDER (Apresentador de Saída)              │
                 │ Formata o OutputDTO para o cliente:            │
                 │ • TwigHtmlResponder (Gera tela HTML/CSS)       │
                 │ • JsonApiResponse   (Gera payload REST)       │
                 └────────────────────────────────────────────────┘
```

---

## 7. Inversão de Dependência (DIP): O Segredo do Baixo Acoplamento

A Inversão de Dependência (a letra **D** do SOLID) é a cola que faz todas as camadas funcionarem juntas sem se acoplarem.

### O Jeito Antigo e Acoplado (❌ Não faça isso):
```php
class ProcessCheckoutUseCase {
    public function execute() {
        // ERRO: O caso de uso está amarrado ao MySQL e ao Stripe concretos!
        $db = new MySqlDatabaseConnection();
        $stripe = new StripeGatewayClient('sk_live_...');
    }
}
```

### O Jeito Limpo com Inversão de Dependência (✅ O Padrão Correto):
O caso de uso depende apenas de **interfaces abstratas**. O contêiner de Injeção de Dependências (PHP-DI / Spring IoC) injeta as implementações reais automaticamente:

```php
class ProcessCheckoutUseCase {
    public function __construct(
        private OrderRepositoryInterface $orderRepository,
        private PaymentGatewayInterface $paymentGateway,
        private UnitOfWorkInterface $uow
    ) {}

    public function execute(CheckoutInputDTO $dto): CheckoutOutputDTO {
        // Código 100% puro e testável com Mocks!
    }
}
```

---

## 8. Passo a Passo: Como Criar uma Nova Feature do Zero Sem Errar

Toda vez que você for desenvolver uma nova funcionalidade no teu sistema, siga rigorosamente esta sequência de 6 passos de dentro para fora:

```
[Passo 1: Domínio]  ➔  [Passo 2: Contrato]  ➔  [Passo 3: Aplicação]
         │
         ▼
[Passo 4: Infra]    ➔  [Passo 5: Entrega]   ➔  [Passo 6: Testes]
```

1. **Passo 1 (Domínio):** Crie ou atualize as Entidades e Value Objects em `src/Domain/` com suas regras invariantes.
2. **Passo 2 (Contrato):** Defina a interface do repositório em `src/Domain/Repositories/`.
3. **Passo 3 (Aplicação):** Crie os DTOs e o Caso de Uso em `src/Application/` orquestrando o fluxo.
4. **Passo 4 (Infraestrutura):** Implemente a interface do repositório em `src/Infrastructure/Persistence/Repositories/` com o SQL/PDO.
5. **Passo 5 (Apresentação):** Crie a Action e o Responder em `src/Http/` e registre a rota.
6. **Passo 6 (Testes):** Crie o teste unitário do Caso de Uso usando mocks em `tests/Unit/`.

---

## 9. Exemplo de Código Ponta a Ponta (Implementação Real)

Imagine a funcionalidade de **"Alterar Senha do Usuário"**:

### 1. Objeto de Valor (Domínio):
```php
namespace App\Domain\Shared\ValueObjects;

final readonly class PasswordHash {
    private string $hash;

    public function __construct(string $plainPassword) {
        if (strlen($plainPassword) < 8) {
            throw new \InvalidArgumentException("A senha deve ter no mínimo 8 caracteres.");
        }
        $this->hash = password_hash($plainPassword, PASSWORD_ARGON2ID);
    }

    public function getHash(): string {
        return $this->hash;
    }
}
```

### 2. Contrato de Repositório (Domínio):
```php
namespace App\Domain\Security\Repositories;

use App\Domain\Security\Entities\User;

interface UserRepositoryInterface {
    public function findById(int $id): ?User;
    public function save(User $user): void;
}
```

### 3. Caso de Uso (Aplicação):
```php
namespace App\Application\Security\UseCases;

use App\Domain\Security\Repositories\UserRepositoryInterface;
use App\Domain\Shared\ValueObjects\PasswordHash;

final class ChangePasswordUseCase {
    public function __construct(
        private UserRepositoryInterface $userRepository
    ) {}

    public function execute(int $userId, string $newPassword): void {
        $user = $this->userRepository->findById($userId);
        if (!$user) {
            throw new \DomainException("Usuário não encontrado.");
        }

        $user->changePassword(new PasswordHash($newPassword));
        $this->userRepository->save($user);
    }
}
```

### 4. Action HTTP ADR (Apresentação):
```php
namespace App\Http\Controllers\Admin;

use App\Application\Security\UseCases\ChangePasswordUseCase;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class ChangePasswordAction {
    public function __construct(
        private ChangePasswordUseCase $useCase
    ) {}

    public function __invoke(Request $request, Response $response): Response {
        $body = (array) $request->getParsedBody();
        
        $this->useCase->execute(
            (int) $request->getAttribute('user_id'),
            (string) ($body['new_password'] ?? '')
        );

        $response->getBody()->write(json_encode(['message' => 'Senha alterada com sucesso!']));
        return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
    }
}
```

---

## 10. Checklist de Auditoria: Como Saber se Você Violou a Arquitetura

Antes de abrir um Pull Request ou considerar sua tarefa concluída, faça este teste rápido de auto-avaliação:

- [ ] **Auditoria de Imports:** A pasta `src/Domain/` importa alguma classe de `src/Infrastructure/` ou de frameworks?  
  *(Se sim: ❌ VIOLAÇÃO GRAVE! O Domínio não pode conhecer detalhes externos).*
- [ ] **Tamanho das Actions:** Alguma Action ou Controller tem mais de 60 linhas de código?  
  *(Se sim: ❌ ALERTA! A Action está acumulando regra de negócio em vez de delegar para um Caso de Uso).*
- [ ] **SQL Fora do Lugar:** Existe qualquer comando SQL (`SELECT`, `INSERT`, `UPDATE`) fora de `src/Infrastructure/Persistence/`?  
  *(Se sim: ❌ VIOLAÇÃO GRAVE! O banco de dados vazou para outras camadas).*
- [ ] **Velocidade dos Testes Unitários:** O teste unitário do teu Caso de Uso precisa de banco de dados ou conexão de internet para rodar?  
  *(Se sim: ❌ ALERTA! O teste não é unitário; você deve usar Mocks das interfaces de repositório).*
- [ ] **Tratamento de Sessão e Auth:** A entidade de domínio lê cookies ou `$_SESSION`?  
  *(Se sim: ❌ VIOLAÇÃO! Sessão e HTTP são resolvidos em Middlewares na camada de Apresentação).*

---

> **Mensagem Final:**  
> A disciplina de manter as camadas isoladas exige esforço consciente no início, mas devolve liberdade infinita ao longo do tempo. Quando teu software for escalado, migrado para a nuvem, transformado em microsserviços ou mantido por dezenas de desenvolvedores, **essa arquitetura garantirá que ele permaneça sólido, testável e elegante.**
