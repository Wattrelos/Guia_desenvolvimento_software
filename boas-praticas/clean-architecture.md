# Clean Architecture (Arquitetura Limpa)

> A Clean Architecture (Arquitetura Limpa) é um padrão de design de software popularizado por Robert C. Martin (conhecido como "Uncle Bob") em 2012. O seu objetivo principal é separar as regras de negócio das tecnologias e ferramentas externas (como bancos de dados, frameworks, interfaces de usuário e APIs).

O maior benefício da Clean Architecture é criar sistemas que são fáceis de testar, fáceis de manter e totalmente independentes de tecnologias, permitindo que você mude o banco de dados ou o framework web no futuro sem tocar nas regras centrais da empresa.

## O Diagrama de Círculos Concêntricos

A Clean Architecture é visualizada como uma cebola ou um alvo com várias camadas. A regra de ouro aqui é a Regra da Dependência: o código das camadas internas nunca pode conhecer ou depender do código das camadas externas. As dependências apontam apenas para dentro.
      ┌─────────────────────────────────────────┐
      │  Camada Externa: Web, DB, UI, Devices  │
      │   ┌─────────────────────────────────┐   │
      │   │  Adaptadores: Controllers, Gateways │
      │   │   ┌─────────────────────────┐   │   │
      │   │   │ Casos de Uso (Use Cases)│   │   │
      │   │   │   ┌─────────────────┐   │   │   │
      │   │   │   │ Entidades (DDD) │   │   │   │
      │   │   │   └─────────────────┘   │   │   │
      │   │   └─────────────────────────┘   │   │
      │   └─────────────────────────────────┘   │
      └─────────────────────────────────────────┘

## 1. Entidades (Entities)

É o coração do sistema. Contém as regras de negócio globais e corporativas. Se o seu software for um banco, aqui ficam as regras de como calcular os juros de uma conta. Esta camada não sabe se os dados vêm de um arquivo texto ou de um banco SQL. Ela é pura lógica de negócio (geralmente modelada usando os conceitos táticos do DDD).

## 2. Casos de Uso (Use Cases / Interactors)

Esta camada contém as regras de negócio específicas da aplicação. Ela dita o fluxo de dados que entra e sai das entidades. Por exemplo: "Transferir Dinheiro" é um caso de uso. Ele busca a conta de origem, valida o saldo (regra da entidade), debita o valor e salva.

## 3. Adaptadores de Interface (Interface Adapters / Presenters / Controllers)

Essa camada serve como um tradutor. Ela pega os dados que vêm da tela ou da API e os converte no formato mais conveniente para os Casos de Uso. É aqui que ficam os Controllers de uma API MVC, os Presenters e as implementações dos Gateways/Repositories.

## 4. Frameworks e Drivers (External)

A camada mais externa, onde ficam as ferramentas tecnológicas. É aqui que o banco de dados real reside (PostgreSQL, MongoDB), o framework web (Spring Boot, ASP.NET Core, NestJS) e as ferramentas de UI. O Uncle Bob defende que o seu framework deve ser um mero detalhe de infraestrutura.

## As 5 Principais Características

- Independente de Frameworks: O sistema não fica refém de uma biblioteca ou arquitetura de terceiros. Você usa os frameworks apenas como ferramentas, não como a fundação do projeto.

- Testabilidade Extrema: Como as regras de negócio (Entidades e Casos de Uso) não conhecem o banco de dados ou a interface, você consegue testá-las integralmente sem precisar subir um servidor web ou conectar a um banco real.

- Independente de UI (Interface): A interface do usuário pode mudar facilmente. Você pode trocar uma tela web por um aplicativo mobile ou por uma interface de linha de comando (CLI) sem alterar uma única linha das regras de negócio.

- Independente de Banco de Dados: Você pode trocar o Oracle pelo MongoDB ou PostgreSQL. Como os Casos de Uso interagem apenas com interfaces (contratos), a lógica interna permanece intacta.

- I ndependente de Agentes Externos: Suas regras de negócio simplesmente não sabem nada sobre o mundo exterior.

## Como ela se conecta com o que vimos antes (DDD e VSA)?

Enquanto a Clean Architecture organiza o sistema separando Tecnologia (fora) de Negócio (dentro) através de camadas horizontais rígidas, a VSA (Vertical Slice) desafia essa divisão propondo que separar por funcionalidade (verticalmente) gera menos fricção no dia a dia.

Muitos desenvolvedores modernos adotam o melhor dos dois mundos: utilizam os princípios de isolamento e inversão de dependência da Clean Architecture para proteger o domínio (DDD), mas organizam os arquivos do projeto seguindo as fatias verticais da VSA.
