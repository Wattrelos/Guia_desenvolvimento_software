# Trilha de Engenharia de Software: Da Concepção ao Código
### *Roadmap Completo, Metodologia de Desenvolvimento e Índice Geral da Trilha*

> 📌 **Apresentação da Trilha:**  
> Esta coleção de documentos constitui um currículo completo de boas práticas de engenharia de software contemporânea. Projetada para estudantes, desenvolvedores e pesquisadores, esta trilha ensina o ciclo de vida completo de um sistema corporativo desde a concepção do problema até a implementação de código resiliente e testável, utilizando o **Beta Engine SaaS** como estudo de caso prático.

---

## 🧭 O Ciclo de Vida da Engenharia de Software (SDLC)

Para entender a ordem natural da construção de qualquer software, pense na metáfora clássica da **Construção de uma Casa**:

```
1. O Terreno e a Demanda       ➔  001: Engenharia de Requisitos (RF, RNF, RN)
2. A Escolha dos Materiais     ➔  002: Decisões Arquiteturais & ADRs (Resiliência)
3. A Planta Baixa Macro        ➔  003: Arquitetura de Referência (Clean, DDD, ADR)
4. A Circulação e Cômodos      ➔  004: Diagramas de Casos de Uso (UML)
5. A Fundação Estrutural       ➔  005: Modelagem de Dados & Diagrama EER
6. As Paredes e Gavetas        ➔  006: Estruturas de Pastas & Padrões (PSR-4)
7. A Automação do Canteiro     ➔  007: Script Automatizado de Scaffolding
8. A Primeira Viga Habitável   ➔  008: Implementação da Primeira Fatia Vertical
```

---

## 📚 Índice Completo dos Módulos da Trilha

### 📄 [001. Engenharia de Requisitos: O Ponto de Partida Absoluto](001_engenharia_de_requisitos.md)
* **O Que Ensina:** Como iniciar um projeto do zero sem adivinhações. A tríade essencial de **Requisitos Funcionais (RF)**, **Não-Funcionais (RNF)** e **Regras de Negócio (RN)**.
* **Tópicos:** Critérios INVEST, Matriz de Rastreabilidade, Linguagem Ubíqua e Requisitos como Código (YAML).

---

### 📄 [002. Decisões Arquiteturais (ADRs) e Resiliência em Produção](002_decisoes_arquiteturais_e_adrs.md)
* **O Que Ensina:** Como registrar formalmente decisões técnicas através de **Architecture Decision Records (ADRs)** e como projetar para a dura realidade dos servidores de hospedagem.
* **Tópicos:** O choque do localhost vs produção real (cPanel/Hostinger sem Redis e RabbitMQ), o princípio da *Degradação Suave (Graceful Degradation)* e design com fallbacks transparentes.

---

### 📄 [003. Arquitetura de Referência Universal](003_arquitetura_de_referencia.md)
* **O Que Ensina:** O padrão arquitetural limpo para qualquer projeto de software (PHP, Java, TypeScript, Go ou C#).
* **Tópicos:** Clean Architecture, Domain-Driven Design (DDD), Ports & Adapters (Hexagonal), Action-Domain-Responder (ADR), a Regra da Dependência e Inversão de Dependência (DIP).

---

### 📄 [004. Diagramas de Casos de Uso (UML) e os 3 Pilares do SaaS](004_diagramas_de_casos_de_uso.md)
* **O Que Ensina:** A modelagem comportamental que responde a *"quem faz o quê no sistema"*.
* **Tópicos:** Atores, herança de papéis, a diferença cristalina entre `<<include>>` e `<<extend>>`, análise dos 3 pilares do SaaS (Cliente, PDV/Balcão e Dashboard) e a conversão de elipses UML em classes `UseCase.php`.

---

### 📄 [005. Modelagem de Dados e o Diagrama EER](005_modelagem_de_dados_e_eer.md)
* **O Que Ensina:** Como o Diagrama EER atua como Fonte Única da Verdade (SSoT) para a estrutura do banco e das entidades.
* **Tópicos:** Notação Pé-de-Galinha (*Crow's Foot*), tipos de dados, chaves primárias/estrangeiras, capacidade generativa e a Tríade de Especificação (EER ➔ Migrations ➔ Casos de Uso).

---

### 📄 [006. Estruturas de Pastas e Padrões de Código](006_estruturas_de_pastas.md)
* **O Que Ensina:** A organização física do código no disco, eliminando pastas "lixão" e quebrando os 5 vícios mais comuns do programador.
* **Tópicos:** Mecânica interna da PSR-4 (Composer), armadilha do Windows vs Linux (*case-sensitivity*), analogia e tabela comparativa completa com Java Spring Boot / Maven.

---

### ⚙️ [007. Script de Automação: Gerador de Estrutura de Pastas](007_gerar_estrutura_pastas.sh)
* **O Que É:** O script executável Bash (`chmod +x`) que constrói fisicamente no disco toda a árvore de diretórios e arquivos modelo da arquitetura alvo com um único comando.
* **Recursos:** Modo simulação (`--dry-run`), idempotência (`mkdir -p`), suporte a `.gitkeep` e estatísticas de criação.

---

### 📄 [008. Implementação da Primeira Fatia Vertical (Vertical Slice)](008_implementacao_fatia_vertical.md)
* **O Que Ensina:** O momento exato de começar a programar sem cometer o erro da geração em lote de classes anêmicas.
* **Tópicos:** Vertical Slice Architecture, a ordem canônica de desenvolvimento (de dentro para fora: Value Objects ➔ Entidades ➔ Contratos ➔ Casos de Uso ➔ Testes com Mocks ➔ Migrations e Repositório PDO ➔ Actions HTTP ADR).

---

### ⚖️ [Nota de Isenção de Responsabilidade (Disclaimer)](disclaimer.md)
* **Amparo Legal:** Nota de conformidade acadêmica, propriedade industrial e *Fair Use* embasada na Lei Federal nº 9.610/1998 (Direitos Autorais) e Lei Federal nº 9.279/1996 (Propriedade Industrial).

---

## 🎯 Como Utilizar Esta Trilha

1. **Para Criar um Projeto do Zero (Greenfield):**  
   Siga a trilha em **ordem sequencial de 001 a 008**. Ela guiará você com segurança desde a entrevista com o cliente até a entrega do primeiro caso de uso funcional e testado.
2. **Para Refatorar um Sistema Existente (Legacy Migration):**  
   Consulte os módulos `003` (Arquitetura Limpa), `005` (EER), `006` (Pastas) e `008` (Fatia Vertical) para reestruturar as camadas do código sem introduzir quebras de regras de negócio.