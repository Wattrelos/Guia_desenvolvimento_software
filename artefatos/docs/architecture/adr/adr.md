# 🏛️ Guia Prático de Architecture Decision Records (ADR)

> **"A arquitetura de software é simplesmente aquilo que é difícil de mudar."** — Martin Fowler  
> O **Architecture Decision Record (ADR)** é um artefato vivo de engenharia de software utilizado para registrar formalmente decisões arquiteturais relevantes tomadas ao longo do ciclo de vida de um projeto, juntamente com o seu contexto, as alternativas avaliadas e os trade-offs envolvidos.

---

## 1. Por que documentar decisões arquiteturais?

Em times de engenharia de software de alta performance, decisões críticas (como escolher um banco de dados, trocar um protocolo de comunicação ou adotar um padrão de consistência) costumam ser tomadas após discussões profundas. No entanto, com o passar dos meses e a rotatividade de desenvolvedores, o raciocínio por trás dessas decisões costuma se perder.

Isso gera problemas graves:
* **Erosão Arquitetural:** Novos desenvolvedores tentam refazer o que já foi discutido porque não sabem por que a solução atual foi desenhada dessa forma.
* **Discussões Circulares:** A equipe volta a debater tecnologias que já haviam sido avaliadas e descartadas no passado.
* **Onboarding Lento:** Novos membros demoram meses para entender o ecossistema e as motivações técnicas do projeto.

O ADR resolve isso transformando o raciocínio arquitetural em **documentação como código (Docs as Code)**, versionada lado a lado no Git.

---

## 2. O Ciclo de Vida de uma Decisão (Status)

Todo ADR possui um ciclo de vida rigoroso baseado em status claros:

```
  ┌──────────┐
  │  Draft   │  (Rascunho inicial do autor)
  └────┬─────┘
       ▼
 ┌───────────┐         Pull Request em Debate
 │ Proposed  │ ──────────────────────────────────┐
 └─────┬─────┘                                   │
       │                                         │
       ├───────────────────┐                     │
       ▼                   ▼                     ▼
 ┌───────────┐       ┌───────────┐         ┌───────────┐
 │ Accepted  │       │ Rejected  │         │ Postponed │
 └─────┬─────┘       └───────────┘         └───────────┘
       │
       ▼
 ┌───────────┐
 │Superseded │ (Substituído por um novo ADR subsequente)
 └─────┬─────┘
       ▼
 ┌───────────┐
 │Deprecated │ (A tecnologia/padrão foi aposentada)
 └───────────┘
```

| Status | Significado | Ação no Git |
| :--- | :--- | :--- |
| **`Draft`** | O documento está sendo redigido pelo autor e ainda não está aberto para discussão formal. | Branch de trabalho do autor. |
| **`Proposed`** | Proposta aberta para debate técnico com o time via Pull Request (PR) ou RFC. | Aberto em PR para aprovação dos revisores. |
| **`Accepted`** | A decisão foi aprovada e acordada pelo time como o padrão oficial a ser seguido. | Mergeado na branch principal (`main`). |
| **`Rejected`** | A proposta foi descartada após avaliação técnica. **Nunca apague o arquivo!** Ele deve ser mergeado para manter o histórico e evitar discussões futuras sobre o mesmo tema. | Mergeado como registro histórico na `main`. |
| **`Superseded`** | Uma decisão passada deixou de ser válida e foi substituída por um novo ADR mais moderno. | O ADR antigo recebe o link do novo: `Substituído por ADR-NNN`. |
| **`Deprecated`** | O recurso ou padrão foi removido do sistema sem substituto direto. | O status é atualizado para alertar os desenvolvedores. |

> [!IMPORTANT]
> **A Regra de Ouro da Imutabilidade:**  
> Uma vez que um ADR é aceito (`Accepted`), ele **NUNCA** deve ter seu contexto ou decisão reescritos para acomodar mudanças futuras. O passado não muda. Se as necessidades do sistema mudaram e uma tecnologia antiga será substituída, cria-se um **novo ADR** (ex: `0015-migracao-de-tecnologia.md`) com a indicação `Supersedes: ADR-0001`.

---

## 3. Padrão de Nomenclatura e Organização de Arquivos

Os arquivos de ADR devem residir na pasta `docs/architecture/adr/` (ou `doc/adr/`), nomeados com um identificador sequencial de 4 dígitos preenchido com zeros à esquerda (*zero-padded*) e o título em *kebab-case*:

```
docs/architecture/adr/
├── 0000-indice-de-decisoes.md
├── 0001-adocao-postgresql-para-checkout.md
├── 0002-adocao-mongodb-para-catalogo-de-produtos.md
├── 0003-uso-de-redis-para-carrinho-e-sessoes.md
└── 0004-adocao-cassandra-para-historico-de-transacoes.md
```

* **Por que números sequenciais?** Facilita a ordenação cronológica na visualização do repositório no GitHub/GitLab e permite referenciar decisões de forma concisa em commits e PRs (ex: *"Conforme definido no ADR-0004..."*).

---

## 4. O Template Oficial de ADR (Formato Recomendado)

Abaixo está o modelo canônico de ADR pronto para uso, baseado no padrão consagrado de Michael Nygard e no padrão **MADR** (*Markdown Architectural Decision Records*):

```markdown
# ADR-NNNN: [Verbo no Infinitivo ou Declaração Curta da Decisão]

* **Status:** [Proposed | Accepted | Rejected | Superseded by ADR-XXXX]
* **Data da Decisão:** AAAA-MM-DD
* **Autores:** Nome do autor ou time
* **Decisores:** Nome dos revisores/Tech Leads/Arquitetos envolvidos
* **Contexto Técnico:** [Link para issue, PR ou RFC relacionada]

---

## 1. Contexto e Declaração do Problema
[Descreva o problema de negócio ou técnico que precisa ser resolvido. Qual é o estado atual do sistema? Quais são as forças e restrições que estão nos empurrando para uma mudança (ex: escalabilidade, custo, tempo de resposta, regras de conformidade)?]

### Critérios de Decisão (Drivers Arquiteturais)
* Requisito 1 (ex: Latência de leitura inferior a 10ms em 99% das requisições).
* Requisito 2 (ex: Consistência ACID inviolável para transações fiscais).
* Requisito 3 (ex: Custo de infraestrutura compatível com o orçamento do projeto).

---

## 2. Opções Consideradas

### Opção 1: [Nome da Tecnologia/Abordagem A]
* **Descrição:** Breve resumo de como a tecnologia seria aplicada.
* **Vantagens (Prós):**
  * Pró 1...
  * Pró 2...
* **Desvantagens (Contras):**
  * Contra 1...
  * Contra 2...

### Opção 2: [Nome da Tecnologia/Abordagem B]
* **Descrição:** Breve resumo de como a tecnologia seria aplicada.
* **Vantagens (Prós):**
  * Pró 1...
* **Desvantagens (Contras):**
  * Contra 1...

---

## 3. Decisão (A Escolha Técnica Justificada)
[Qual opção foi escolhida e por quê? Justifique com base nos critérios de decisão estabelecidos acima. Explique por que os pontos fortes da opção escolhida superam suas desvantagens e por que as alternativas foram descartadas.]

---

## 4. Consequências e Trade-offs

Toda decisão arquitetural traz impactos positivos e negativos. É fundamental torná-los explícitos:

### Consequências Positivas (Ganhos)
* Ganho de performance, desacoplamento ou facilidade de escala obtida...

### Consequências Negativas e Riscos (Débitos/Trade-offs Aceitos)
* Complexidade operacional adicional introduzida...
* Curva de aprendizado necessária para a equipe...
* Como este risco será mitigado?

### Consequências Neutras
* Ajustes esperados na rotina de deploy, monitoramento ou CI/CD...

---

## 5. Plano de Conformidade e Validação
[Como a equipe irá garantir que esta decisão seja cumprida na prática? Ex: regras no linter, testes de arquitetura (ArchUnit), validações no CI, checklists de PR.]
```

---

## 5. Quando NÃO colocar um documento gigante no `adr/`?

Um ADR deve ser **conciso, direto e focado na decisão**, idealmente contendo entre 1 e 3 páginas no máximo.

Se você conduziu um estudo de viabilidade extenso de 40 páginas, com múltiplos benchmarks sob carga, gráficos de estresse de memória e orçamentos detalhados de cloud:
1. Salve o estudo completo no diretório de documentação exploratória (ex: `docs/architecture/research/` ou na Wiki/Confluence da empresa).
2. Escreva o **ADR** de forma resumida, concentrando-se no contexto, no resumo das opções, na decisão final e nos links que apontam para o estudo completo.

---

## 6. Diferença entre ADR, RFC e Documentação de Código

| Artefato | Propósito | Quando é criado? | Estado Final |
| :--- | :--- | :--- | :--- |
| **RFC / Tech Proposal** | Estimular debate e colher feedbacks da equipe sobre um problema aberto. | Durante a fase de exploração e design de uma nova funcionalidade. | É arquivada ou convertida em um ADR após a deliberação. |
| **ADR (Record)** | Registrar o que foi decidido, o porquê e os trade-offs assumidos. | No momento em que o time bate o martelo sobre a solução. | Permanece no repositório como registro permanente e imutável. |
| **Doc de Código (README / Wikis)** | Explicar como o software funciona hoje e como utilizá-lo. | Mantido e atualizado continuamente conforme o código evolui. | Mutável, reflete sempre o estado atual do sistema. |

---

## 7. Checklist para Revisão de um ADR no Pull Request

Antes de aprovar o PR de um novo ADR, os revisores técnicos devem checar:
* [ ] O problema técnico e os motivos da mudança estão claramente explicados?
* [ ] Mais de uma opção técnica foi considerada de forma honesta (sem criar opções "espantalho")?
* [ ] Os contras e trade-offs da opção vencedora foram reconhecidos e possuem plano de mitigação?
* [ ] A decisão está alinhada com as metas do negócio e a capacidade da equipe?
* [ ] O título segue o padrão numérico `NNNN-titulo.md` e o status inicial está correto?
