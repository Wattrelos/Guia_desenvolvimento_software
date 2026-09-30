# 📜 Guia Prático de Changelogs (Histórico de Mudanças)

> **"Um changelog é um arquivo que contém uma lista com curadoria humana e ordenada cronologicamente de alterações notáveis para cada versão de um projeto."** — *Keep a Changelog* (Olivier Lacan)  
> O **Changelog** é um artefato vivo de engenharia de software e governança técnica. Ele traduz a complexidade de centenas de commits, revisões de código e refatorações em uma narrativa clara, estruturada e voltada para o impacto gerado para desenvolvedores, equipes de QA, operadores de infraestrutura (SRE) e usuários finais.

---

## 1. Por que manter um Changelog estruturado?

Em ciclos de desenvolvimento acelerados, a tentação comum é confiar que o histórico de commits do Git (`git log`) é suficiente para documentar o que mudou no software. No entanto, o `git log` é projetado para **máquinas e rastreamento atômico de código**, não para comunicação técnica humana.

A ausência de um changelog formal e com curadoria gera problemas graves:
* **Incerteza e Medo de Atualização (*Upgrade Anxiety*):** Desenvolvedores e clientes hesitam em atualizar dependências ou versões do sistema por não saberem o que pode quebrar.
* **Quebras Silenciosas (*Silent Breaking Changes*):** Modificações em contratos de API, schemas de banco de dados ou variáveis de ambiente passam despercebidas até causarem falhas em produção.
* **Ruído Cognitivo e Perda de Tempo:** Para entender uma nova entrega, equipes de suporte e QA precisam garimpar centenas de mensagens de commit crípticas como `"fix typo"`, `"wip"`, `"ajustes no pr"` ou `"merge branch main"`.
* **Auditoria de Conformidade e Release:** Rastrear qual versão exata introduziu determinada correção ou atendeu a uma exigência regulatória torna-se uma tarefa investigativa demorada.

O Changelog resolve essa lacuna aplicando o paradigma de **Documentação como Código (*Docs as Code*)**: um histórico versionado junto ao código-fonte, revisado via Pull Request e mantido com rigor semântico.

---

## 2. Princípios Canônicos e o Padrão *Keep a Changelog*

Este guia adota os princípios internacionais consagrados pelo padrão **[Keep a Changelog](https://keepachangelog.com/)**, integrado às diretrizes de **Versionamento Semântico ([SemVer 2.0.0](https://semver.org/))**.

### Os 6 Princípios Fundamentais:
1. **Feito para Humanos, Não para Máquinas:** As entradas devem explicar *o que* mudou e *qual é o impacto*, não simplesmente listar diffs de código.
2. **Cada Versão / Incremento tem sua Seção:** As alterações não devem ficar amontoadas em um fluxo contínuo sem fronteiras claras de versão ou fatia de entrega.
3. **Ordem Cronológica Inversa:** As versões ou fatias mais recentes sempre aparecem no topo do documento.
4. **Datas no Padrão ISO 8601:** Todas as datas devem seguir o formato estrito `AAAA-MM-DD` (ex: `2026-09-30`).
5. **Destaque Mandatório para *Breaking Changes*:** Qualquer alteração incompatível com versões anteriores deve ser destacada com alertas visuais explícitos.
6. **Categorização Canônica das Mudanças:** Toda alteração deve ser classificada sob verbos padronizados.

---

## 3. As 6 Categorias Canônicas de Alterações

Para garantir clareza e previsibilidade na leitura, cada modificação deve ser agrupada sob uma das seguintes categorias padronizadas:

| Categoria | Ícone / Verbo | Significado e Aplicação | Impacto SemVer Típico |
| :--- | :--- | :--- | :--- |
| **`Added`** | 🚀 **Adicionado** | Novos recursos, endpoints, comandos ou funcionalidades entregues. | `MINOR` (`x.Y.z`) |
| **`Changed`** | 🔄 **Modificado** | Alterações no comportamento, fluxo ou assinatura de recursos existentes. | `MINOR` ou `MAJOR` |
| **`Deprecated`** | ⚠️ **Obsoleto** | Recursos que ainda funcionam, mas cuja remoção já está agendada para versões futuras. | `MINOR` (`x.Y.z`) |
| **`Removed`** | 🗑️ **Removido** | Recursos, parâmetros, métodos ou endpoints descontinuados e eliminados do código. | `MAJOR` (`X.y.z`) |
| **`Fixed`** | 🐛 **Corrigido** | Correção de defeitos, falhas lógicas ou comportamentos inesperados. | `PATCH` (`x.y.Z`) |
| **`Security`** | 🛡️ **Segurança** | Correções de vulnerabilidades, atualizações de dependências críticas ou reforço de autenticação. | `PATCH` ou `MINOR` |

> [!NOTE]
> **Extensão de Engenharia para Sistemas Web e Microsserviços:**  
> Além das categorias canônicas do *Keep a Changelog*, adotamos a subseção **`Infrastructure & Environment`** (ou **Ambiente e Operações**) para documentar migrações de banco de dados (`DDL`), novas chaves obrigatórias no arquivo `.env` e atualizações de runtime (ex: versão do PHP/Node/Docker).

---

## 4. O Fluxo de Trabalho: Changelog Monolítico vs Changelog Fragmentado por Fatia

Em projetos corporativos, adotamos uma abordagem em duas camadas para manter a rastreabilidade:

```
  ┌────────────────────────────────────────────────────────┐
  │  1. Desenvolvimento da Fatia Vertical (Vertical Slice) │
  │  - Desenvolvedor implementa o incremento (ex: DP-040)  │
  │  - Redige o Changelog da Fatia no mesmo PR:            │
  │    artefatos/docs/changelogs/0040-setup_wizard.md      │
  └───────────────────────────┬────────────────────────────┘
                              │
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │  2. Revisão Técnica de Código (Pull Request)           │
  │  - Revisores conferem tarefas concluídas               │
  │  - Validam métricas de testes e arquivos afetados      │
  │  - Verificam breaking changes e novas variáveis .env   │
  └───────────────────────────┬────────────────────────────┘
                              │ Merge na main
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │  3. Release Consolidada / Tag SemVer                   │
  │  - O changelog consolidado (CHANGELOG.md na raiz)      │
  │    agrega as fatias mergeadas sob a versão da release  │
  │  - Notificação aos clientes e stakeholders             │
  └────────────────────────────────────────────────────────┘
```

1. **Changelog Fragmentado por Fatia / Deploy Plan (`artefatos/docs/changelogs/NNNN-slug.md`):**  
   Focado na rastreabilidade atômica do time de engenharia. Acompanha o Pull Request da fatia vertical, documentando arquivos alterados, suites de teste executadas, comandos de migração e detalhes de infraestrutura.
2. **Changelog Consolidado de Release (`CHANGELOG.md` na raiz do projeto):**  
   Focado nos consumidores do software. Agrupa os incrementos entregues sob uma versão semântica (ex: `v1.2.0`), filtrando detalhes de baixo nível e destacando benefícios e correções de impacto.

---

## 5. Padrão de Nomenclatura e Organização dos Arquivos

Os changelogs de fatia vertical e planos de deploy devem residir no diretório `artefatos/docs/changelogs/`, utilizando numeração sequencial de 4 dígitos (*zero-padded*) correspondente ao identificador da fatia/plano e nome em *kebab-case*:

```
artefatos/docs/changelogs/
├── changelogs.md                        # Este guia e manual de referência
├── 0001-autenticacao-jwt-cliente.md     # Changelog do incremento 0001
├── 0002-catalogo-produtos-balcao.md     # Changelog do incremento 0002
├── ...
└── 0040-setup_wizard.md                 # Changelog da fatia 0040 (Setup Wizard)
```

* **Por que numeração de 4 dígitos?** Garante ordenação alfabética e cronológica idêntica no explorador de arquivos e no GitHub, além de permitir referenciamento direto em commits e issues (ex: `ref: CL-0040`).

---

## 6. Template Oficial: Changelog de Fatia Vertical / Deploy Plan

Abaixo está o modelo canônico obrigatório para documentar fatias verticais e incrementos de deploy no repositório:

````markdown
# Changelog - [Nome da Funcionalidade ou Módulo] ([Identificador da Fatia/Card])

* **Identificador:** CL-NNNN (ex: CL-0040)
* **Deploy Plan / Referência:** DP-NNNN ou Issue #NNN
* **Data da Conclusão:** AAAA-MM-DD
* **Autor(es):** Nome do autor ou time responsável
* **Revisor(es):** Tech Lead / Revisores do Pull Request
* **Status:** Concluído | Em Homologação | Rollback Realizado
* **Tipo de Alteração Predominante:** Added | Changed | Fixed | Security

---

## 1. Resumo Executivo
[Descreva de forma concisa e clara em 1 a 2 parágrafos o que esta fatia entregou, qual dor de negócio ou necessidade técnica ela solucionou e qual o benefício gerado para a aplicação.]

---

## 2. Impacto no Sistema e Quebras de Compatibilidade (*Breaking Changes*)
> [!IMPORTANT]
> **Atenção:** [Especifique se há quebra de retrocompatibilidade, alteração de assinaturas de métodos públicos, descontinuação de rotas HTTP ou necessidade de execução de scripts de migração antes do deploy.]

* **Retrocompatibilidade:** Preservada | Quebrada (Exige ação)
* **Ações Requeridas:** [Ex: Atualizar `.env`, rodar migration, limpar cache do Redis]

---

## 3. Alterações de Infraestrutura e Ambiente

### Variáveis de Ambiente (`.env`)
* `NOVA_VARIAVEL`: Descrição e valor de exemplo (adicionada a `.env.example`).

### Banco de Dados / Migrations
* Scripts executados: `backend/resources/schema/install.sql` (ou migration via Phinx/Flyway).
* Tabelas criadas/alteradas: `settings`, `tenants`, `audit_logs`.

---

## 4. Tarefas Concluídas e Arquivos Modificados

### 🚀 Added (Novas Funcionalidades)
- [x] **Nome do Componente / Funcionalidade**
  - Descrição da alteração e motivação técnica.
  - Arquivo criado/modificado: [`caminho/para/arquivo.php`](file:///caminho/para/arquivo.php).

### 🔄 Changed (Modificações e Refatorações)
- [x] **Nome da Refatoração**
  - Ajuste em comportamento existente.
  - Arquivo alterado: [`caminho/para/controller.php`](file:///caminho/para/controller.php).

### 🐛 Fixed (Correções de Bugs)
- [x] **Correção de Falha**
  - Causa raiz e solução adotada.
  - Arquivo corrigido: [`caminho/para/service.php`](file:///caminho/para/service.php).

---

## 5. Métricas de Qualidade e Evidências de Teste

| Tipo de Teste | Suíte / Arquivo | Quantidade de Testes | Asserções | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Unitário** | `tests/Unit/...Test.php` | N testes | N asserções | ✅ Aprovado |
| **Integração** | `tests/Integration/...Test.php` | N testes | N asserções | ✅ Aprovado |
| **Total** | Cobertura Global da Fatia | N testes | N asserções | 100% Pass |

---

## 6. Procedimento de Verificação e Rollback

### Verificação Pós-Deploy (*Sanity Check*)
1. Acessar a rota `https://dominio.com/rota-teste` e verificar resposta HTTP 200.
2. Conferir logs da aplicação em busca de exceções.

### Plano de Contingência / Rollback
1. Reverter o commit na branch principal (`git revert`).
2. Executar script de rollback de migração de banco caso aplicável.
````

> [!TIP]
> **Exemplo Prático Canônico:**  
> Uma implementação completa e real deste padrão pode ser consultada diretamente em [`0040-setup_wizard.md`](file:///var/www/html/Guia_desenvolvimento_software/artefatos/docs/changelogs/0040-setup_wizard.md), que documenta com precisão a entrega da fatia vertical do assistente de instalação e setup automatizado.

---

## 7. Template Oficial: `CHANGELOG.md` Consolidado (Nível de Release)

Para a raiz do projeto (`CHANGELOG.md`), adota-se o formato tradicional do *Keep a Changelog*:

````markdown
# Changelog

Todas as alterações notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Unreleased]
### Added
- Suporte a autenticação biométrica via WebAuthn.

## [1.2.0] - 2026-09-30
### Added
- Assistente visual de instalação inicial (*Setup Wizard*) para configuração guiada do ambiente ([CL-0040](file:///var/www/html/Guia_desenvolvimento_software/artefatos/docs/changelogs/0040-setup_wizard.md)).
- Validação assíncrona de credenciais do banco de dados MySQL via requisição AJAX.

### Changed
- Refatorado middleware de inicialização para proteger rotas administrativas antes do setup.

### Fixed
- Corrigida condição de corrida na escrita atômica do arquivo de configuração `.env`.

### Security
- Forçada geração de credenciais de Super Admin com algoritmo Argon2id.

## [1.1.0] - 2026-08-15
...
````

---

## 8. Anti-Patterns Comuns: O que NÃO fazer em um Changelog

* ❌ **Copiar o `git log` sem filtro:**  
  *Exemplo Ruim:* `git commit -m "fix"`, `git commit -m "update"`, `git commit -m "ajuste botão"`.  
  *Por que é ruim:* Não agrega valor semântico e obriga o leitor a deduzir o que de fato mudou.
* ❌ **Mensagens Vagas e Indeterminadas:**  
  *Exemplo Ruim:* `"Melhorias gerais no sistema e pequenas correções."`  
  *Por que é ruim:* Nenhuma equipe de QA ou cliente consegue testar ou validar "melhorias gerais".
* ❌ **Esconder *Breaking Changes* ou Novas Variáveis:**  
  *Exemplo Ruim:* Modificar o schema do banco ou introduzir nova chave no `.env` sem documentar na seção de infraestrutura.
* ❌ **Changelog Póstumo e Desincronizado:**  
  Escrever o changelog semanas após o código estar em produção. O changelog deve nascer **junto com o Pull Request** da funcionalidade.
* ❌ **Deixar Tarefas Incompletas sem Justificativa:**  
  Manter caixas desmarcadas (`- [ ]`) no changelog de uma fatia dada como concluída.

---

## 9. Matriz Comparativa: Changelog vs Outros Artefatos

| Artefato | Público Principal | Finalidade | Nível de Detalhe | Momento de Escrita |
| :--- | :--- | :--- | :--- | :--- |
| **`git log`** | Desenvolvedor / Git | Rastreabilidade atômica linha a linha de cada commit. | Altamente técnico e detalhado. | A cada commit local. |
| **Changelog de Fatia (`0040-...md`)** | Engenharia, QA, Tech Lead | Evidenciar a entrega técnica, tarefas, arquivos e testes de um card/fatia. | Técnico focado em componentes e testes. | Durante a implementação do PR. |
| **`CHANGELOG.md` Consolidado** | Usuários, Clientes, PMs, SRE | Comunicar novas features, correções e breaking changes por versão de release. | Gerencial e funcional com foco em valor e impacto. | No fechamento da release / tag SemVer. |
| **ADR (Decision Record)** | Arquitetos e Desenvolvedores | Justificar o *porquê* de uma decisão arquitetural tomada. | Arquitetural, conceituado em prós, contras e trade-offs. | Antes da implementação da decisão. |

---

## 10. Checklist de Revisão de Changelog em Pull Request

Antes de aprovar o PR de uma fatia de desenvolvimento, os revisores devem validar:

* [ ] O changelog da fatia foi criado/atualizado no diretório `artefatos/docs/changelogs/` seguindo a convenção de nomenclatura?
* [ ] As alterações estão categorizadas corretamente (`Added`, `Changed`, `Fixed`, etc.)?
* [ ] Todas as novas variáveis de ambiente (`.env`) e scripts de banco de dados foram listados com instruções claras?
* [ ] Há evidências e métricas concretas da suíte de testes automatizados (unitários e de integração)?
* [ ] Caso haja quebra de compatibilidade (*Breaking Change*), ela está destacada com alerta explícito?
* [ ] Os links para os arquivos modificados e referências de tickets/deploy plans estão funcionando?
