# Modelagem de Dados e o Diagrama EER: A Fundação Estrutural do Software
### *Como o Diagrama EER Atua como Fonte Única da Verdade (SSoT) e se Conecta a Migrations, Classes de Domínio e Casos de Uso*

> 📌 **Nota de Estudo:**  
> Um diagrama **EER (Enhanced Entity-Relationship / Entidade-Relacionamento Estendido)** é a espinha dorsal de qualquer sistema orientado a dados. Errar na sintaxe de um controller custa 5 minutos de correção; errar na modelagem de um banco de dados em produção pode custar semanas de migração de dados e prejuízos financeiros incalculáveis.

---

## 🧭 Sumário
1. [A Grande Pergunta: O Diagrama EER Pode Centralizar Tudo?](#1-a-grande-pergunta-o-diagrama-eer-pode-centralizar-tudo)
2. [Anatomia de um Diagrama EER Profissional em PlantUML](#2-anatomia-de-um-diagrama-eer-profissional-em-plantuml)
3. [Decifrando a Notação Pé-de-Galinha (Crow's Foot)](#3-decifrando-a-notação-pé-de-galinha-crows-foot)
4. [Capacidade Gerativa: O Que Desenvolvedores e Agentes IA Conseguem Gerar](#4-capacidade-gerativa-o-que-desenvolvedores-e-agentes-ia-conseguem-gerar)
5. [A Fronteira do Diagrama: Por Que Precisamos de Artefatos Complementares?](#5-a-fronteira-do-diagrama-por-que-precisamos-de-artefatos-complementares)
6. [A Tríade de Especificação na Engenharia de Software Moderna](#6-a-tríade-de-especificação-na-engenharia-de-software-moderna)
7. [Exemplo Prático: Da Notação EER à Migration e Classe de Domínio](#7-exemplo-prático-da-notação-eer-à-migration-e-classe-de-domínio)
8. [Boas Práticas de Manutenção do Diagrama no Git](#8-boas-práticas-de-manutenção-do-diagrama-no-git)

---

## 1. A Grande Pergunta: O Diagrama EER Pode Centralizar Tudo?

Como estudante e desenvolvedor, é muito comum ter a seguinte dúvida:
> *"O arquivo `.puml` é capaz de centralizar todas as informações sobre classes e tabelas em um só lugar, atuando como Fonte Única da Verdade (Single Source of Truth), ou são necessários artefatos complementares?"*

### A Resposta:
- **Para a ESTRUTURA e o ESTADO (Dados): SIM!**  
  Um diagrama EER bem modelado como o nosso [`docs/database/EERDiagram.puml`](/docs/database/EERDiagram.puml) contém 100% das informações necessárias para mapear tabelas, tipos de dados, chaves primárias, chaves estrangeiras e cardinalidades.
- **Para o COMPORTAMENTO e REGRAS (Negócio): NÃO!**  
  O banco armazena o estado dos dados, mas o software executa regras dinâmicas (ex: *como* a senha é criptografada, *quando* o desconto pode ser aplicado, ou *quais* eventos devem ser disparados). Essas regras não cabem em um diagrama EER sem torná-lo ilegível e visualmente poluído.

---

## 2. Anatomia de um Diagrama EER Profissional em PlantUML

Tomando como referência o arquivo [EERDiagram.puml](│/docs/database/EERDiagram.puml), veja os elementos essenciais que tornam um diagrama compreensível tanto para seres humanos quanto para compiladores e Agentes de IA:

```plantuml
package "Customer Module" #D5E8D4 {
    entity Customer #F5FBF3 {
        * id : int <<PK>>
        --
        * customer_group_id : int <<FK>>
        * email : varchar(96)
        * password : varchar(255)
        * status : tinyint(1)
        address_id : int <<FK>>
        * date_added : datetime
    }
}
```

### Elementos-Chave:
1. **Nome da Entidade:** Corresponde à tabela no singular ou plural (definido na convenção do projeto).
2. **Separador (`--`):** Divide a chave primária (`PK`) dos demais atributos da tabela.
3. **Asterisco (`*`):** Indica **obrigatoriedade (`NOT NULL`)**. Campos sem asterisco (como `address_id`) são campos opcionais (**`NULL`**).
4. **Tipagem Explícita:** `varchar(96)`, `decimal(15,4)`, `tinyint(1)`, `datetime`. Isso elimina qualquer ambiguidade na hora de criar a migration.
5. **Estereótipos (`<<PK>>`, `<<FK>>`):** Identificam instantaneamente chaves primárias e chaves estrangeiras para resolução de relacionamentos.

---

## 3. Decifrando a Notação Pé-de-Galinha (Crow's Foot)

A notação de relacionamentos no PlantUML utiliza símbolos geométricos padronizados pela indústria (*Barker's Notation / Crow's Foot*):

```
SÍMBOLO NO PLANTUML       CARDINALIDADE          SIGNIFICADO PRÁTICO
─────────────────────────────────────────────────────────────────────────────────────────────
||-right-||               1 : 1 (Estrito)        Um Registro A exige exatamente Um Registro B.
|o-right-||               0..1 : 1 (Opcional)    Um Registro A pode ou não ter Um Registro B.
||-down-|{                1 : N (Obrigatório)    Um Registro A possui Um ou Mais Registros B.
|o-down-|{                0..1 : N (Opcional)    Um Registro A pode possuir Zero ou Mais Registros B.
}o-down-o{                N : N (Muitos p/ Muitos) Exige tabela intermediária (tabela associativa/pivot).
```

### Exemplo no Nosso E-commerce:
```plantuml
' Um Cliente tem 1 ou mais Endereços (1:N obrigatório)
Customer "1" ||-down-|{ Address : "has"

' Um Cliente pode ou não ter um Perfil de Afiliado (0..1:1 opcional)
Customer "1" |o-right-|| CustomerAffiliate : "has affiliate profile"

' Um Pedido contém 1 ou mais Itens (1:N)
Order "1" ||-down-|{ OrderProduct : "contains"
```

---

## 4. Capacidade Gerativa: O Que Desenvolvedores e Agentes IA Conseguem Gerar

A partir de um arquivo `.puml` detalhado, ferramentas de engenharia de software e modelos de Inteligência Artificial conseguem gerar com facilidade:

```
                          ┌────────────────────────┐
                          │   docs/database/       │
                          │   EERDiagram.puml      │
                          └───────────┬────────────┘
                                      │
            ┌─────────────────────────┼─────────────────────────┐
            ▼                         ▼                         ▼
 ┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────┐
 │   Migrations SQL    │   │ Classes de Domínio  │   │  Mappers e DAOs     │
 │  (database/migr./)  │   │   (src/Domain/)     │   │ (src/Infrastruct./) │
 │                     │   │                     │   │                     │
 │ • CREATE TABLE      │   │ • POPOs fortemente  │   │ • Tradução coluna   │
 │ • Tipos exatos      │   │   tipados (PHP 8.4) │   │   ⇄ propriedade     │
 │ • Constraints FK    │   │ • Coleções tipadas  │   │ • Queries seguras   │
 │ • Nullability       │   │ • Getters / Imutab. │   │   com QueryBuilder  │
 └─────────────────────┘   └─────────────────────┘   └─────────────────────┘
```

1. **Scripts DDL de Banco de Dados (Migrations):** Nomes de tabelas, tipos de colunas, chaves primárias e relacionamentos com integridade referencial (`FOREIGN KEY`).
2. **Classes de Entidade / POPOs (Plain Old PHP Objects):** Classes puras com tipagem estrita no PHP 8.4 ou Java, incluindo propriedades privadas e coleções de objetos relacionados.
3. **Data Mappers e DAOs:** A camada de persistência necessária para transformar linhas do banco em instâncias de objetos vivos na memória.

---

## 5. A Fronteira do Diagrama: Por Que Precisamos de Artefatos Complementares?

Tentar colocar **todos os detalhes de um sistema** em um único diagrama EER é um erro clássico que gera diagramas com milhares de nós que ninguém consegue ler.

O diagrama deve ser a **Planta Estrutural**. Os detalhes finos pertencem a artefatos especializados:

| Detalhe de Engenharia | Por que não cabe no `.puml`? | Onde deve ser especificado? |
| :--- | :--- | :--- |
| **Comportamentos / Métodos** | Diagramas de dados mostram *o que a entidade tem*, não *o que ela faz*. | **Casos de Uso** (`docs/business/use-cases/`) |
| **Regras de Cascata (`CASCADE`)** | Poluiria o gráfico com anotações de `ON DELETE CASCADE` ou `RESTRICT`. | **Migrations SQL** (`database/migrations/`) |
| **Validações de Formato (Regex)** | Expressões regulares de CPF, e-mail e regras de tamanho mínimo. | **DTOs / OpenAPI Schemas** (`docs/specs/`) |
| **Índices de Performance** | Índices compostos de banco (ex: `INDEX(loja_id, status)`). | **Scripts de Migrations / DB Tuning** |
| **Transações ACID Complexas** | Lógica de estorno, rollback e bloqueio concorrente (*Optimistic Lock*). | **Casos de Uso & Unit of Work** |

---

## 6. A Tríade de Especificação na Engenharia de Software Moderna

Projetos de alta maturidade não dependem de um único documento salvador. Eles utilizam a **Tríade de Especificação**:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        A TRÍADE DE ESPECIFICAÇÃO                       │
├────────────────────────────────────────────────────────────────────────┤
│ 1. O Diagrama EER (.puml) ➔ A PLANTA BAIXA ESTRUTURAL                  │
│    ↳ Fonte visual e canônica: Entidades, tipos, PKs, FKs e conexões.   │
├────────────────────────────────────────────────────────────────────────┤
│ 2. As Migrations SQL (.sql / .php) ➔ A IMPLEMENTAÇÃO FÍSICA NO BANCO   │
│    ↳ O código real que roda no MySQL (AUTO_INCREMENT, ENGINE=InnoDB,   │
│      regras de DELETE CASCADE, índices compostos de performance).      │
├────────────────────────────────────────────────────────────────────────┤
│ 3. Os Casos de Uso & Schemas (.md / .yaml) ➔ O COMPORTAMENTO DE NEGÓCIO│
│    ↳ Validações, fluxos de permissão, regras de negócio e limites.    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 7. Exemplo Prático: Da Notação EER à Migration e Classe de Domínio

Vejamos na prática como o módulo de **Clientes e Endereços** do nosso `EERDiagram.puml` se transforma diretamente em código funcional:

### 1. Trecho no `EERDiagram.puml`:
```plantuml
entity Customer {
    * id : int <<PK>>
    --
    * email : varchar(96)
    * cpf_cnpj : varchar(20)
    * status : tinyint(1)
    address_id : int <<FK>>
    * date_added : datetime
}

entity Address {
    * id : int <<PK>>
    --
    * customer_id : int <<FK>>
    * street : varchar(255)
    * number : varchar(32)
    complement : varchar(255)
}

Customer "1" ||-down-|{ Address : "has"
```

### 2. A Migration Gerada (`database/migrations/001_create_customers.sql`):
```sql
CREATE TABLE `customers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `email` VARCHAR(96) NOT NULL,
    `cpf_cnpj` VARCHAR(20) NOT NULL,
    `status` TINYINT(1) NOT NULL DEFAULT 1,
    `address_id` INT NULL,
    `date_added` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_customer_default_address` 
        FOREIGN KEY (`address_id`) REFERENCES `addresses`(`id`) 
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `addresses` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `customer_id` INT NOT NULL,
    `street` VARCHAR(255) NOT NULL,
    `number` VARCHAR(32) NOT NULL,
    `complement` VARCHAR(255) NULL,
    CONSTRAINT `fk_address_customer` 
        FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) 
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 3. A Classe de Entidade Gerada (`src/Domain/Customer/Entities/Customer.php`):
```php
namespace App\Domain\Customer\Entities;

use DateTimeInterface;

final class Customer
{
    public function __construct(
        public readonly int $id,
        public string $email,
        public string $cpfCnpj,
        public bool $status,
        public ?int $addressId,
        public readonly DateTimeInterface $dateAdded,
        /** @var Address[] Coleção tipada originada da relação 1:N */
        private array $addresses = []
    ) {}

    public function addAddress(Address $address): void
    {
        $this->addresses[] = $address;
    }

    /** @return Address[] */
    public function getAddresses(): array
    {
        return $this->addresses;
    }
}
```

---

## 8. Boas Práticas de Manutenção do Diagrama no Git

Um diagrama desatualizado é pior do que a ausência de diagrama, pois ele induz novos desenvolvedores e IAs ao erro.

> [!TIP]
> **A Regra do Commit Casado:**  
> Toda vez que uma alteração estrutural no banco for necessária (ex: adicionar uma nova coluna ou criar uma nova tabela), o arquivo `docs/database/EERDiagram.puml` **deve ser alterado no mesmo commit** em que o arquivo de migration for criado.

### Checklist de Qualidade do Diagrama:
- [ ] Todo relacionamento possui sua respectiva chave estrangeira (`<<FK>>`) declarada na entidade correspondente.
- [ ] Todos os campos obrigatórios estão anotados com asterisco (`*`).
- [ ] Relacionamentos de muitos-para-muitos ($N:N$) são explicitados através de uma tabela associativa intermediária (ex: `ProductToCategory`).
- [ ] A legenda de mapeamento de tipos está presente para orientar o autoloader da linguagem.

---

> **Conclusão:**  
> O diagrama `EERDiagram.puml` cumpre com excelência o papel de **Fonte Única da Verdade para a Estrutura de Dados**. Ao combiná-lo com as **Migrations SQL** e os **Casos de Uso**, você constrói uma fundação de engenharia sólida, transparente e perfeitamente preparada para a colaboração com outros desenvolvedores e Agentes de Inteligência Artificial.
