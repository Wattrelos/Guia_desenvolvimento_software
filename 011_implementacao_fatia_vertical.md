# Implementação Orientada a Domínio: A Primeira Fatia Vertical (Vertical Slice)
### *Do Scaffolding ao Primeiro Caso de Uso Funcional: A Ordem Canônica de Implementação Sem Classes Anêmicas*

> 📌 **Nota de Transição:**  
> Concluímos toda a fase de concepção estrutural: Requisitos (001), Decisões de Arquitetura e Resiliência (002), Arquitetura Limpa (003), Casos de Uso (004), Modelagem EER (005) e a Árvore de Diretórios (006/007).  
> **Agora entramos na fase de construção de código.** Este módulo ensina como dar o primeiro passo na programação sem cair na armadilha de criar centenas de classes vazias e sem violar a Regra da Dependência.

---

## 🧭 Sumário
1. [O Dilema do Desenvolvedor: Gerar Todas as Classes ou Programar por Demanda?](#1-o-dilema-do-desenvolvedor-gerar-todas-as-classes-ou-programar-por-demanda)
2. [O Conceito de Fatia Vertical (Vertical Slice Architecture)](#2-o-conceito-de-fatia-vertical-vertical-slice-architecture)
3. [A Ordem Canônica de Implementação: De Dentro para Fora](#3-a-ordem-canônica-de-implementação-de-dentro-para-fora)
4. [Passo 0: Inicialização do Ecossistema e Autoload (Composer PSR-4)](#4-passo-0-inicialização-do-ecossistema-e-autoload-composer-psr-4)
5. [Passo 1: O Núcleo do Domínio (Value Objects, Entidades e Contratos)](#5-passo-1-o-núcleo-do-domínio-value-objects-entidades-e-contratos)
6. [Passo 2: A Camada de Aplicação (DTOs e Caso de Uso Orquestrador)](#6-passo-2-a-camada-de-aplicação-dtos-e-caso-de-uso-orquestrador)
7. [Passo 3: A Blindagem por Testes Unitários com Mocks](#7-passo-3-a-blindagem-por-testes-unitários-com-mocks)
8. [Passo 4: A Camada de Infraestrutura (Migrations DDL e Repositório Concreto)](#8-passo-4-a-camada-de-infraestrutura-migrations-ddl-e-repositório-concreto)
9. [Passo 5: A Camada de Apresentação (Action ADR e Registro de Rotas)](#9-passo-5-a-camada-de-apresentação-action-adr-e-registro-de-rotas)
10. [Checklist de Conclusão da Fatia Vertical](#10-checklist-de-conclusão-da-fatia-vertical)

---

## 1. O Dilema do Desenvolvedor: Gerar Todas as Classes ou Programar por Demanda?

Ao terminar o scaffolding de pastas gerado pelo script [`007_gerar_estrutura_pastas.sh`](007_gerar_estrutura_pastas.sh), a tentação imediata da maioria dos desenvolvedores é abrir o editor e gerar em lote 50 arquivos de modelo baseados nas tabelas do banco.

### ❌ O Anti-Pattern da "Fatia Horizontal em Massa":
- Criar todas as entidades de uma vez só com `getters` e `setters` vazios.
- Criar todos os controllers antes de ter casos de uso.
- **Resultado:** Modelos anêmicos, centenas de linhas de código morto sem testes, acoplamento prematuro e exaustão antes de ver a primeira requisição funcionar.

### ✅ O Padrão da Engenharia Moderna: "Fatia Vertical Guiada por Caso de Uso":
- Escolhe-se **um único caso de uso âncora** (ex: `Cadastrar Cliente` ou `Autenticar Usuário`).
- Percorrem-se todas as camadas exclusivamente para atender a esse fluxo.
- **Resultado:** Em poucas horas há uma funcionalidade 100% testada, rodando da rota HTTP ao banco de dados, validando toda a arquitetura de ponta a ponta.

---

## 2. O Conceito de Fatia Vertical (Vertical Slice Architecture)

Em vez de fatiar o sistema por camadas técnicas horizontais isoladas, desenvolve-se uma lâmina completa que corta todas as camadas concêntricas da Arquitetura Limpa:

```
                  ┌──────────────────────────────────────────────┐
                  │ 1. Value Objects (Cpf, Email, PasswordHash)  │ ◄── DOMAIN
                  └──────────────────────┬───────────────────────┘
                                         │
                  ┌──────────────────────▼───────────────────────┐
                  │ 2. Entidade Pura & Regras (Customer)         │ ◄── DOMAIN
                  └──────────────────────┬───────────────────────┘
                                         │
                  ┌──────────────────────▼───────────────────────┐
                  │ 3. Contrato de Repositório (Interface)       │ ◄── DOMAIN
                  └──────────────────────┬───────────────────────┘
                                         │
                  ┌──────────────────────▼───────────────────────┐
                  │ 4. DTOs e Caso de Uso (RegisterCustomer)     │ ◄── APPLICATION
                  └──────────────────────┬───────────────────────┘
                                         │
                  ┌──────────────────────▼───────────────────────┐
                  │ 5. Migration SQL + Repositório PDO Concreto  │ ◄── INFRASTRUCTURE
                  └──────────────────────┬───────────────────────┘
                                         │
                  ┌──────────────────────▼───────────────────────┐
                  │ 6. Action HTTP + Responder JSON + Rota       │ ◄── PRESENTATION
                  └──────────────────────────────────────────────┘
```

---

## 3. A Ordem Canônica de Implementação: De Dentro para Fora

A regra pétrea da Arquitetura Limpa diz: **o centro não conhece a periferia**. Portanto, a ordem natural e mais produtiva de codificação é rigorosamente **de dentro para fora**:

```
[Domínio Puro] ➔ [Contratos] ➔ [Casos de Uso] ➔ [Testes Unitários] ➔ [Persistência] ➔ [Entrega HTTP]
```

1. **Por que começar pelos Value Objects?** Porque eles não dependem de nada no universo além de tipos primitivos (strings, inteiros). Eles já nascem testáveis.
2. **Por que a Entidade vem antes do banco?** Porque o comportamento do negócio dita o que precisa ser persistido, e não as limitações de uma tabela SQL.
3. **Por que o Caso de Uso vem antes do Controller?** Porque a regra da aplicação pode ser acionada por HTTP, por CLI de terminal ou por uma fila assíncrona.

---

## 4. Passo 0: Inicialização do Ecossistema e Autoload (Composer PSR-4)

Antes de criar a primeira classe PHP, é obrigatório registrar o mapa de namespaces no `composer.json` raiz para que a PSR-4 funcione perfeitamente:

```json
{
    "name": "empresa/beta-engine-saas",
    "description": "Beta Engine SaaS - Core Architecture",
    "type": "project",
    "require": {
        "php": "^8.2"
    },
    "require-dev": {
        "phpunit/phpunit": "^10.0"
    },
    "autoload": {
        "psr-4": {
            "App\\": "backend/src/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Tests\\": "tests/"
        }
    }
}
```

Atualize o autoloader no terminal:
```bash
composer dump-autoload
```

---

## 5. Passo 1: O Núcleo do Domínio (Value Objects, Entidades e Contratos)

Inspirando-nos nos requisitos reais do e-commerce corporativo (vistos no [`BetaEngine`](file:///var/www/html/Guia_desenvolvimento_software/BetaEngine)), vamos modelar o caso de uso: **Cadastro de Novo Cliente** (`RF-001`).

No padrão antigo (MVC legado), o controller recebia um array cru `$_POST`, chamava métodos gigantescos e misturava regras com SQL. Na nova arquitetura limpa, o Domínio é 100% puro, fortemente tipado e autovalidável.

### 5.1. Criando os Value Objects (Autovalidáveis e Imutáveis)

#### Objeto de Valor: E-mail
Arquivo: `backend/src/Domain/Shared/ValueObjects/Email.php`

```php
<?php

declare(strict_types=1);

namespace App\Domain\Shared\ValueObjects;

use InvalidArgumentException;

final readonly class Email
{
    private string $value;

    public function __construct(string $email)
    {
        $filtered = filter_var(trim($email), FILTER_VALIDATE_EMAIL);
        if ($filtered === false) {
            throw new InvalidArgumentException("O e-mail informado é inválido: {$email}");
        }
        $this->value = strtolower($filtered);
    }

    public function getValue(): string
    {
        return $this->value;
    }

    public function equals(Email $other): bool
    {
        return $this->value === $other->value;
    }

    public function __toString(): string
    {
        return $this->value;
    }
}
```

#### Objeto de Valor: CPF ou CNPJ Brasileiro
No `BetaEngine`, o campo `cpfCnpj` existe na entidade `Customer`, mas costumava ser uma simples string solta. Na arquitetura moderna, nós blindamos o dado com um Value Object:

Arquivo: `backend/src/Domain/Shared/ValueObjects/CpfCnpj.php`

```php
<?php

declare(strict_types=1);

namespace App\Domain\Shared\ValueObjects;

use InvalidArgumentException;

final readonly class CpfCnpj
{
    private string $cleanDigits;

    public function __construct(string $value)
    {
        $digits = preg_replace('/\D/', '', $value);
        if ($digits === null || !in_array(strlen($digits), [11, 14], true)) {
            throw new InvalidArgumentException("Documento deve ser um CPF (11 dígitos) ou CNPJ (14 dígitos) válido.");
        }

        if (preg_match('/^(\d)\1*$/', $digits)) {
            throw new InvalidArgumentException("Documento inválido (dígitos repetidos).");
        }

        $this->cleanDigits = $digits;
    }

    public function getDigits(): string
    {
        return $this->cleanDigits;
    }

    public function isCpf(): bool
    {
        return strlen($this->cleanDigits) === 11;
    }

    public function isCnpj(): bool
    {
        return strlen($this->cleanDigits) === 14;
    }

    public function __toString(): string
    {
        return $this->cleanDigits;
    }
}
```

---

### 5.2. Criando a Entidade de Domínio Rica
No MVC antigo do `BetaEngine`, as entidades herdavam de `BaseEntity` e continham dezenas de getters e setters que permitiam alterar qualquer dado a qualquer momento (modelo anêmico).

Na nova arquitetura com **PSR-4 (`backend/src/Domain/Customer/Entities/Customer.php`)**, a entidade protege seu próprio estado e expressa a linguagem ubíqua do negócio:

Arquivo: `backend/src/Domain/Customer/Entities/Customer.php`

```php
<?php

declare(strict_types=1);

namespace App\Domain\Customer\Entities;

use App\Domain\Shared\ValueObjects\CpfCnpj;
use App\Domain\Shared\ValueObjects\Email;
use DateTimeImmutable;

final class Customer
{
    public function __construct(
        private ?int $id,
        private int $customerGroupId,
        private int $storeId,
        private string $firstname,
        private string $lastname,
        private Email $email,
        private string $telephone,
        private CpfCnpj $cpfCnpj,
        private string $passwordHash,
        private bool $status,
        private bool $newsletter,
        private DateTimeImmutable $dateAdded
    ) {}

    /**
     * Named Constructor: Garante a criação de um cliente em estado 100% válido.
     */
    public static function create(
        string $firstname,
        string $lastname,
        Email $email,
        string $telephone,
        CpfCnpj $cpfCnpj,
        string $passwordHash,
        int $customerGroupId = 1,
        int $storeId = 0,
        bool $newsletter = false
    ): self {
        return new self(
            id: null,
            customerGroupId: $customerGroupId,
            storeId: $storeId,
            firstname: trim($firstname),
            lastname: trim($lastname),
            email: $email,
            telephone: trim($telephone),
            cpfCnpj: $cpfCnpj,
            passwordHash: $passwordHash,
            status: true,
            newsletter: $newsletter,
            dateAdded: new DateTimeImmutable()
        );
    }

    public function getId(): ?int { return $this->id; }
    public function getCustomerGroupId(): int { return $this->customerGroupId; }
    public function getStoreId(): int { return $this->storeId; }
    public function getFirstname(): string { return $this->firstname; }
    public function getLastname(): string { return $this->lastname; }
    public function getFullName(): string { return trim("{$this->firstname} {$this->lastname}"); }
    public function getEmail(): Email { return $this->email; }
    public function getTelephone(): string { return $this->telephone; }
    public function getCpfCnpj(): CpfCnpj { return $this->cpfCnpj; }
    public function getPasswordHash(): string { return $this->passwordHash; }
    public function isStatus(): bool { return $this->status; }
    public function isNewsletter(): bool { return $this->newsletter; }
    public function getDateAdded(): DateTimeImmutable { return $this->dateAdded; }

    public function attachId(int $id): void
    {
        $this->id = $id;
    }
}
```

---

### 5.3. Definindo o Contrato de Persistência (Porta de Saída)
No `BetaEngine`, o repositório (`CustomerRepository.php`) misturava consultas SQL, sessões de usuário, auto-login e regras de formulário.

Na arquitetura limpa, o **Domínio define apenas o contrato** (Interface). A implementação com SQL fica isolada na camada de **Infraestrutura**:

Arquivo: `backend/src/Domain/Customer/Repositories/CustomerRepositoryInterface.php`

```php
<?php

declare(strict_types=1);

namespace App\Domain\Customer\Repositories;

use App\Domain\Customer\Entities\Customer;
use App\Domain\Shared\ValueObjects\CpfCnpj;
use App\Domain\Shared\ValueObjects\Email;

interface CustomerRepositoryInterface
{
    public function findById(int $id): ?Customer;
    public function findByEmail(Email $email): ?Customer;
    public function findByCpfCnpj(CpfCnpj $cpfCnpj): ?Customer;
    public function save(Customer $customer): Customer;
}
```

---

## 6. Passo 2: A Camada de Aplicação (DTOs e Caso de Uso Orquestrador)

A camada de aplicação recebe os dados da requisição, valida regras de orquestração (ex: verificar se o e-mail ou CPF já existem) e delega para o domínio.

### 6.1. DTO de Entrada (Input DTO)
Arquivo: `backend/src/Application/Customer/DTOs/RegisterCustomerInputDTO.php`

```php
<?php

declare(strict_types=1);

namespace App\Application\Customer\DTOs;

final readonly class RegisterCustomerInputDTO
{
    public function __construct(
        public string $firstname,
        public string $lastname,
        public string $email,
        public string $telephone,
        public string $cpfCnpj,
        public string $plainPassword,
        public int $customerGroupId = 1,
        public int $storeId = 0,
        public bool $newsletter = false
    ) {}
}
```

### 6.2. DTO de Saída (Output DTO)
Arquivo: `backend/src/Application/Customer/DTOs/RegisterCustomerOutputDTO.php`

```php
<?php

declare(strict_types=1);

namespace App\Application\Customer\DTOs;

final readonly class RegisterCustomerOutputDTO
{
    public function __construct(
        public int $customerId,
        public string $fullName,
        public string $email,
        public string $telephone,
        public string $cpfCnpj,
        public string $dateAdded
    ) {}
}
```

### 6.3. O Caso de Uso (Application Service / Interactor)
Arquivo: `backend/src/Application/Customer/UseCases/RegisterCustomerUseCase.php`

```php
<?php

declare(strict_types=1);

namespace App\Application\Customer\UseCases;

use App\Application\Customer\DTOs\RegisterCustomerInputDTO;
use App\Application\Customer\DTOs\RegisterCustomerOutputDTO;
use App\Domain\Customer\Entities\Customer;
use App\Domain\Customer\Repositories\CustomerRepositoryInterface;
use App\Domain\Shared\ValueObjects\CpfCnpj;
use App\Domain\Shared\ValueObjects\Email;
use DomainException;

final class RegisterCustomerUseCase
{
    public function __construct(
        private readonly CustomerRepositoryInterface $repository
    ) {}

    public function execute(RegisterCustomerInputDTO $input): RegisterCustomerOutputDTO
    {
        $email = new Email($input->email);
        $cpfCnpj = new CpfCnpj($input->cpfCnpj);

        // 1. Verificações de Unicidade
        if ($this->repository->findByEmail($email) !== null) {
            throw new DomainException("Já existe uma conta cadastrada com este e-mail.");
        }

        if ($this->repository->findByCpfCnpj($cpfCnpj) !== null) {
            throw new DomainException("Já existe uma conta cadastrada com este CPF/CNPJ.");
        }

        // 2. Criptografia Segura (Argon2id ou BCRYPT padrão)
        $passwordHash = password_hash($input->plainPassword, PASSWORD_DEFAULT);

        // 3. Criação da Entidade de Negócio
        $customer = Customer::create(
            firstname: $input->firstname,
            lastname: $input->lastname,
            email: $email,
            telephone: $input->telephone,
            cpfCnpj: $cpfCnpj,
            passwordHash: $passwordHash,
            customerGroupId: $input->customerGroupId,
            storeId: $input->storeId,
            newsletter: $input->newsletter
        );

        // 4. Persistência via Porta de Saída
        $savedCustomer = $this->repository->save($customer);

        return new RegisterCustomerOutputDTO(
            customerId: (int) $savedCustomer->getId(),
            fullName: $savedCustomer->getFullName(),
            email: $savedCustomer->getEmail()->getValue(),
            telephone: $savedCustomer->getTelephone(),
            cpfCnpj: $savedCustomer->getCpfCnpj()->getDigits(),
            dateAdded: $savedCustomer->getDateAdded()->format('Y-m-d H:i:s')
        );
    }
}
```

---

## 7. Passo 3: A Blindagem por Testes Unitários com Mocks

Note que até este momento **nenhum comando SQL foi escrito e nenhum banco foi ligado**, mas a inteligência de negócios já pode ser testada em milissegundos com o PHPUnit:

Arquivo: `tests/Unit/Application/Customer/RegisterCustomerUseCaseTest.php`

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Customer;

use App\Application\Customer\DTOs\RegisterCustomerInputDTO;
use App\Application\Customer\UseCases\RegisterCustomerUseCase;
use App\Domain\Customer\Entities\Customer;
use App\Domain\Customer\Repositories\CustomerRepositoryInterface;
use DomainException;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;

final class RegisterCustomerUseCaseTest extends TestCase
{
    public function testDeveCadastrarClienteComSucesso(): void
    {
        $repositoryMock = $this->createMock(CustomerRepositoryInterface::class);

        $repositoryMock->method('findByEmail')->willReturn(null);
        $repositoryMock->method('findByCpfCnpj')->willReturn(null);
        $repositoryMock->method('save')->willReturnCallback(function (Customer $customer) {
            $customer->attachId(42);
            return $customer;
        });

        $useCase = new RegisterCustomerUseCase($repositoryMock);

        $input = new RegisterCustomerInputDTO(
            firstname: "João",
            lastname: "Silva",
            email: "joao.silva@exemplo.com",
            telephone: "(11) 98765-4321",
            cpfCnpj: "12345678909",
            plainPassword: "senhaSegura123"
        );

        $output = $useCase->execute($input);

        $this->assertSame(42, $output->customerId);
        $this->assertSame("João Silva", $output->fullName);
        $this->assertSame("joao.silva@exemplo.com", $output->email);
    }

    public function testDeveRejeitarEmailDuplicado(): void
    {
        $this->expectException(DomainException::class);
        $this->expectExceptionMessage("Já existe uma conta cadastrada com este e-mail.");

        $existingCustomer = $this->createMock(Customer::class);
        $repositoryMock = $this->createMock(CustomerRepositoryInterface::class);
        $repositoryMock->method('findByEmail')->willReturn($existingCustomer);

        $useCase = new RegisterCustomerUseCase($repositoryMock);

        $input = new RegisterCustomerInputDTO(
            firstname: "Outro",
            lastname: "Usuario",
            email: "joao.silva@exemplo.com",
            telephone: "1199999999",
            cpfCnpj: "98765432100",
            plainPassword: "senha"
        );

        $useCase->execute($input);
    }

    public function testDeveLancarExcecaoSeCpfForInvalido(): void
    {
        $this->expectException(InvalidArgumentException::class);

        $repositoryMock = $this->createMock(CustomerRepositoryInterface::class);
        $useCase = new RegisterCustomerUseCase($repositoryMock);

        $input = new RegisterCustomerInputDTO(
            firstname: "Maria",
            lastname: "Santos",
            email: "maria@exemplo.com",
            telephone: "1199999999",
            cpfCnpj: "11111111111", // Dígitos repetidos
            plainPassword: "senha"
        );

        $useCase->execute($input);
    }
}
```

---

## 8. Passo 4: A Camada de Infraestrutura (Migrations e Repositório Concreto)

Agora que a lógica está 100% blindada, conectamos a infraestrutura física (MySQL/PDO), inspirada nas colunas reais mapeadas no `BetaEngine`.

### 8.1. A Migration SQL (Schema Real)
Arquivo: `database/migrations/001_create_customers_table.sql`

```sql
CREATE TABLE IF NOT EXISTS `customers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `customer_group_id` INT NOT NULL DEFAULT 1,
    `store_id` INT NOT NULL DEFAULT 0,
    `firstname` VARCHAR(32) NOT NULL,
    `lastname` VARCHAR(32) NOT NULL,
    `email` VARCHAR(96) NOT NULL UNIQUE,
    `telephone` VARCHAR(32) NOT NULL,
    `cpf_cnpj` VARCHAR(20) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `newsletter` TINYINT(1) NOT NULL DEFAULT 0,
    `status` TINYINT(1) NOT NULL DEFAULT 1,
    `date_added` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_customers_email` (`email`),
    INDEX `idx_customers_cpf_cnpj` (`cpf_cnpj`),
    INDEX `idx_customers_store` (`store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 8.2. O Repositório Concreto com PDO
Arquivo: `backend/src/Infrastructure/Persistence/Repositories/SqlCustomerRepository.php`

```php
<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Repositories;

use App\Domain\Customer\Entities\Customer;
use App\Domain\Customer\Repositories\CustomerRepositoryInterface;
use App\Domain\Shared\ValueObjects\CpfCnpj;
use App\Domain\Shared\ValueObjects\Email;
use DateTimeImmutable;
use PDO;

final class SqlCustomerRepository implements CustomerRepositoryInterface
{
    public function __construct(private readonly PDO $pdo) {}

    public function findById(int $id): ?Customer
    {
        $stmt = $this->pdo->prepare("SELECT * FROM customers WHERE id = :id LIMIT 1");
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row ? $this->mapRowToEntity($row) : null;
    }

    public function findByEmail(Email $email): ?Customer
    {
        $stmt = $this->pdo->prepare("SELECT * FROM customers WHERE email = :email LIMIT 1");
        $stmt->execute(['email' => $email->getValue()]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row ? $this->mapRowToEntity($row) : null;
    }

    public function findByCpfCnpj(CpfCnpj $cpfCnpj): ?Customer
    {
        $stmt = $this->pdo->prepare("SELECT * FROM customers WHERE cpf_cnpj = :cpf_cnpj LIMIT 1");
        $stmt->execute(['cpf_cnpj' => $cpfCnpj->getDigits()]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row ? $this->mapRowToEntity($row) : null;
    }

    public function save(Customer $customer): Customer
    {
        $sql = "INSERT INTO customers 
                (customer_group_id, store_id, firstname, lastname, email, telephone, cpf_cnpj, password_hash, newsletter, status, date_added)
                VALUES 
                (:group_id, :store_id, :firstname, :lastname, :email, :telephone, :cpf_cnpj, :password_hash, :newsletter, :status, :date_added)";

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([
            'group_id'      => $customer->getCustomerGroupId(),
            'store_id'      => $customer->getStoreId(),
            'firstname'     => $customer->getFirstname(),
            'lastname'      => $customer->getLastname(),
            'email'         => $customer->getEmail()->getValue(),
            'telephone'     => $customer->getTelephone(),
            'cpf_cnpj'      => $customer->getCpfCnpj()->getDigits(),
            'password_hash' => $customer->getPasswordHash(),
            'newsletter'    => $customer->isNewsletter() ? 1 : 0,
            'status'        => $customer->isStatus() ? 1 : 0,
            'date_added'    => $customer->getDateAdded()->format('Y-m-d H:i:s'),
        ]);

        $customer->attachId((int) $this->pdo->lastInsertId());
        return $customer;
    }

    private function mapRowToEntity(array $row): Customer
    {
        return new Customer(
            id: (int) $row['id'],
            customerGroupId: (int) $row['customer_group_id'],
            storeId: (int) $row['store_id'],
            firstname: (string) $row['firstname'],
            lastname: (string) $row['lastname'],
            email: new Email((string) $row['email']),
            telephone: (string) $row['telephone'],
            cpfCnpj: new CpfCnpj((string) $row['cpf_cnpj']),
            passwordHash: (string) $row['password_hash'],
            status: (bool) $row['status'],
            newsletter: (bool) $row['newsletter'],
            dateAdded: new DateTimeImmutable((string) $row['date_added'])
        );
    }
}
```

---

## 9. Passo 5: A Camada de Apresentação (Action ADR e Rotas)

No padrão MVC legado, os controllers eram classes gigantescas (`CustomerController.php`) com métodos `login()`, `logout()`, `register()`, `forgot()`.

No padrão moderno **Action-Domain-Responder (ADR)** com Slim 4 (adotado pelo `BetaEngine/backend/core/Controller/Actions/`), cada arquivo é uma **Action de responsabilidade única**:

Arquivo: `backend/src/Http/Controllers/Storefront/RegisterCustomerAction.php`

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Storefront;

use App\Application\Customer\DTOs\RegisterCustomerInputDTO;
use App\Application\Customer\UseCases\RegisterCustomerUseCase;
use DomainException;
use InvalidArgumentException;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

/**
 * RegisterCustomerAction - Processa o registro de cliente via POST /api/v1/customers/register.
 */
final class RegisterCustomerAction
{
    public function __construct(
        private readonly RegisterCustomerUseCase $useCase
    ) {}

    public function __invoke(Request $request, Response $response): Response
    {
        $body = (array) $request->getParsedBody();
        if (empty($body)) {
            $raw = (string) $request->getBody();
            $body = json_decode($raw, true) ?? [];
        }

        try {
            $input = new RegisterCustomerInputDTO(
                firstname: (string) ($body['firstname'] ?? ''),
                lastname: (string) ($body['lastname'] ?? ''),
                email: (string) ($body['email'] ?? ''),
                telephone: (string) ($body['telephone'] ?? ''),
                cpfCnpj: (string) ($body['cpf_cnpj'] ?? $body['cpfCnpj'] ?? ''),
                plainPassword: (string) ($body['password'] ?? ''),
                customerGroupId: (int) ($body['customer_group_id'] ?? 1),
                storeId: (int) ($body['store_id'] ?? 0),
                newsletter: !empty($body['newsletter'])
            );

            $output = $this->useCase->execute($input);

            $response->getBody()->write((string) json_encode([
                'success' => true,
                'data'    => $output
            ], JSON_UNESCAPED_UNICODE));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(201);

        } catch (InvalidArgumentException | DomainException $e) {
            $response->getBody()->write((string) json_encode([
                'success' => false,
                'error'   => $e->getMessage()
            ], JSON_UNESCAPED_UNICODE));

            return $response
                ->withHeader('Content-Type', 'application/json')
                ->withStatus(422);
        }
    }
}
```

### 9.2. Vinculando na Rota da Loja
Arquivo: `backend/config/routes/storefront.php`

```php
<?php

declare(strict_types=1);

use App\Http\Controllers\Storefront\RegisterCustomerAction;
use Slim\App;

return function (App $app) {
    // Endpoint RESTful de registro
    $app->post('/api/v1/customers/register', RegisterCustomerAction::class);
};
```

---

## 10. Checklist de Conclusão da Fatia Vertical

Ao finalizar a implementação, verifique cada item antes de passar para a próxima funcionalidade:

```
┌────────────────────────────────────────────────────────────────────────┐
│               CHECKLIST DE CONCLUSÃO DA FATIA VERTICAL                 │
├────────────────────────────────────────────────────────────────────────┤
│ [ ] O Domínio (Value Objects e Entidades) não tem "use PDO",           │
│     "use Slim" ou bibliotecas de terceiros?                            │
│ [ ] A interface do Repositório está no Domínio e a implementação       │
│     está na Infraestrutura?                                            │
│ [ ] O Caso de Uso possui teste unitário rodando com Mock em < 10ms?    │
│ [ ] A Migration SQL reflete com exatidão a modelagem do EER?           │
│ [ ] A Action HTTP é de ação única e retorna HTTP 201 ou 422?           │
└────────────────────────────────────────────────────────────────────────┘
```

> **Conclusão:**  
> Ao dominar o desenvolvimento em **Fatias Verticais de Dentro para Fora**, você elimina o receio de "por onde começar a codificar". Em vez do antigo MVC acoplado, você tem um ecossistema modular, robusto, 100% testável e perfeitamente preparado para a escala corporativa.
