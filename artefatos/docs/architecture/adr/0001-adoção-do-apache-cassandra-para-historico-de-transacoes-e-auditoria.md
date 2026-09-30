# ADR-0001: Adoção do Apache Cassandra para Histórico de Transações e Auditoria

* **Status:** Accepted
* **Data da Decisão:** 2026-09-30
* **Autores:** Equipe de Arquitetura e Engenharia de Dados
* **Decisores:** Tech Lead de Backend, Arquiteto de Software, Especialista em Banco de Dados / SRE
* **Contexto Técnico:** RFC-0042 (Desacoplamento de Histórico e Logs da Camada Transacional)
* **Documento Relacionado:** [Boas Práticas na Arquitetura de Persistência Poliglota](file:///var/www/html/tutoriais/databases/boas-praticas-uso-bd.md)

---

## 1. Contexto e Declaração do Problema

Nossa plataforma de e-commerce e pagamentos atingiu a marca de 5 milhões de transações mensais, com projeção de crescimento acelerado para 20 milhões no próximo ano. 

Atualmente, o banco de dados relacional primário (**PostgreSQL**) é responsável por todo o ciclo de vida dos dados: desde a autorização de pagamento e controle atômico de estoque até o armazenamento de históricos permanentes de transações, extratos dos usuários (*financial ledger*) e logs detalhados de auditoria técnica e fiscal.

Com o crescimento exponencial do volume de dados, identificamos sintomas críticos de gargalo na arquitetura atual:
1. **Inchaço de Tabelas e Degradação de Índices (*Table Bloat*):** A tabela de movimentações financeiras ultrapassou 120 milhões de linhas. Os índices B-Tree tornaram-se gigantescos, consumindo a maior parte da memória RAM do servidor para *buffer pool* e tornando as escritas cada vez mais caras.
2. **Contenção de I/O no Checkout:** Escritas massivas de logs de auditoria e históricos concorrem diretamente pelo mesmo subsistema de disco e CPU do processo de checkout, aumentando o tempo de resposta da autorização de pedidos em horários de pico.
3. **Lentidão em Consultas de Extrato:** Clientes antigos com milhares de transações enfrentam lentidão ao carregar extratos paginados no aplicativo, pois o PostgreSQL precisa buscar páginas esparsas no disco e executar ordenações dinâmicas (`ORDER BY created_at DESC`).
4. **Custo Operacional de Expurgo de Logs:** Scripts agendados que executam `DELETE FROM audit_logs WHERE created_at < NOW() - INTERVAL '90 days'` causam picos severos de lock, geram fragmentação de disco e demandam rotinas agressivas de `VACUUM`.

### Critérios de Decisão (Drivers Arquiteturais)
* **Alta Vazão de Gravação (*Write-Heavy*):** Capacidade de ingerir dezenas de milhares de eventos e transações por segundo sem degradação de latência.
* **Leitura Cronológica O(1) de Extrato:** Consultas ao extrato financeiro paginado de um usuário devem responder em menos de 10ms, sem custo computacional de ordenação em tempo de execução.
* **Imutabilidade e Segurança:** O histórico financeiro e os logs de auditoria são estritamente cumulativos (*Append-Only*). Nenhum registro passado deve sofrer alteração.
* **Expurgo Automático de Dados Efêmeros:** Descarte transparente de logs antigos sem gerar bloqueios de tabela ou sobrecarga de I/O.
* **Alta Disponibilidade e Tolerância a Falhas:** O sistema de histórico e auditoria não pode possuir pontos únicos de falha (*Zero SPOF*).

---

## 2. Opções Consideradas

### Opção 1: Manter PostgreSQL com Particionamento Declarativo de Tabelas (*Table Partitioning*)
Dividir as tabelas de movimentações e logs em partições mensais nativas do PostgreSQL (`PARTITION BY RANGE (created_at)`).

* **Vantagens (Prós):**
  * Mantém a mesma stack de tecnologia; time já possui domínio pleno de SQL e PostgreSQL.
  * Preserva garantias ACID nativas e integridade referencial com chaves estrangeiras.
  * O descarte de dados antigos pode ser feito via `DROP TABLE` da partição, o que é rápido e não gera *dead tuples*.
* **Desvantagens (Contras):**
  * Continua competindo pelos mesmos recursos de hardware (disco, CPU, conexões) da base de checkout, a menos que seja isolado em uma réplica com replicação lógica complexa.
  * Consultas que buscam transações de um usuário específico ao longo de vários meses precisam varrer múltiplas partições (*cross-partition queries*), degradando o tempo de resposta.
  * Escalabilidade de escrita continua sendo vertical (*Scale-Up*).

### Opção 2: Armazenar Histórico e Logs no MongoDB (Coleção Dedicada)
Criar coleções segregadas de histórico de transações e logs no cluster MongoDB já existente, utilizando referenciamento inverso por `account_id` e índice TTL.

* **Vantagens (Prós):**
  * MongoDB já faz parte da arquitetura do catálogo, reaproveitando a infraestrutura existente.
  * Documentos BSON flexíveis facilitam o armazenamento de metadados heterogêneos de eventos de auditoria.
  * Suporte nativo a *TTL Indexes* para expurgo de dados.
* **Desvantagens (Contras):**
  * A thread de expurgo de TTL do MongoDB roda a cada 60 segundos fazendo buscas em índice e emitindo deleções de documentos, gerando picos periódicos de I/O em coleções com centenas de milhões de registros.
  * Alto consumo de memória RAM do motor *WiredTiger* para manter índices B-Tree de coleções massivas em cache.
  * Não oferece o mesmo modelo determinístico de particionamento físico e ordenação contígua no disco que bancos colunares oferecem para séries temporais.

### Opção 3: Adotar Apache Cassandra / ScyllaDB (Wide-Column Store com LSM-Tree)
Implementar um cluster de Apache Cassandra (ou ScyllaDB) dedicado para armazenar séries temporais imutáveis, organizado por chave de partição (`account_id` / `entity_id`) e chave de ordenação física decrescente (`created_at DESC`).

* **Vantagens (Prós):**
  * **Motor LSM-Tree (Log-Structured Merge-Tree):** Gravações sequenciais em memória (*MemTable*) e *CommitLog*, entregando altíssima taxa de ingestão com latência sub-milissegundo, imune a locks de linha.
  * **Leitura O(1) de Extratos:** A chave primária `PRIMARY KEY ((account_id), created_at, transaction_id)` garante que os registros de um mesmo usuário fiquem contíguos no mesmo nó e gravados no disco já na ordem cronológica inversa (*Clustering Key*).
  * **TTL Nativo por Linha:** Registros de logs e telemetria gravados com `USING TTL 7776000` (90 dias) são expurgados diretamente nas etapas normais de compactação de disco (*Compaction*), sem custos adicionais de `DELETE`.
  * **Arquitetura Masterless:** Tolerância a falhas nativa sem nó primário/mestre; escalabilidade horizontal linear (*Scale-Out*) adicionando nós ao anel.
* **Desvantagens (Contras):**
  * Nova tecnologia na stack: exige curva de aprendizado da equipe de backend e SRE para administração de cluster e modelagem orientada a consultas (*Query-Driven Modeling*).
  * Não possui `JOIN`s, transações multi-tabelas ACID ou agregações dinâmicas flexíveis.
  * Risco de degradação por *Tombstones* caso operações de `UPDATE` ou `DELETE` sejam realizadas incorretamente.

### Opção 4: Elasticsearch / OpenSearch
Enviar todos os logs e eventos de histórico de transações para índices diários ou mensais no Elasticsearch.

* **Vantagens (Prós):**
  * Excelente capacidade para busca textual livre e filtros combinados arbitrários.
  * Integração nativa com dashboards e visualização via Kibana/OpenSearch Dashboards.
* **Desvantagens (Contras):**
  * Custo proibitivo de memória RAM (JVM Heap) e armazenamento para retenção de longo prazo de transações financeiras.
  * Não foi projetado para atuar como repositório canônico transacional de extrato financeiro de alta confiabilidade.
  * Custo de reindexação e manutenção de *shards* e *rollover policies* para volumes maciços.

---

## 3. Decisão (A Escolha Técnica Justificada)

Decidimos **adotar o Apache Cassandra (ou ScyllaDB)** como banco de dados NoSQL especializado para armazenar o **Histórico de Transações Financeiras (Extrato/Ledger)** e as **Trilhas de Auditoria e Logs de Entidades**.

### Fundamentação Técnica da Escolha:
1. **Separação Clara de Responsabilidades:**  
   O PostgreSQL continuará sendo a autoridade máxima e estrita para a **execução e autorização da transação** (garantias ACID, concorrência pessimista de saldo e reserva de estoque). Uma vez que a transação é finalizada com sucesso, o registro imutável do extrato é propagado assincronamente para o Cassandra.
2. **Desacoplamento Assíncrono via Transactional Outbox:**  
   A gravação no Cassandra não adicionará latência à API do cliente. O serviço de checkout grava um evento na tabela `outbox_events` do PostgreSQL dentro da mesma transação ACID do pedido. Um worker lê do **RabbitMQ** e insere o registro histórico no Cassandra de forma desacoplada e idempotente.
3. **Eficiência de Consulta e Eliminação de Ordenação:**  
   Com a modelagem `WITH CLUSTERING ORDER BY (created_at DESC)`, a exibição dos 20 lançamentos mais recentes do extrato de qualquer cliente é uma operação de busca contígua em disco, consumindo frações de milissegundo de CPU.
4. **Expurgo sem Débito Técnico de I/O:**  
   A trilha de auditoria técnica terá expiração de 90 dias configurada nativamente via `USING TTL`, eliminando totalmente as rotinas destrutivas de limpeza de dados no banco relacional.

---

## 4. Consequências e Trade-offs

### Consequências Positivas (Ganhos)
* **Alívio Imediato no Banco Relacional:** Redução de mais de 75% no volume de gravações diárias no PostgreSQL, eliminando contenção de disco e reduzindo drasticamente o tamanho dos backups.
* **Performance Preditiva do Extrato:** O tempo de resposta para consulta de extrato do cliente se torna constante ($O(1)$) e independente da idade da conta ou do número total de transações na plataforma.
* **Escalabilidade Horizontal Sustentável:** Conforme o volume de transações crescer, basta adicionar nós padronizados ao anel do Cassandra, sem necessidade de janelas de manutenção para migrações verticais de servidores.
* **Zero Downtime em Manutenção:** A arquitetura peer-to-peer permite upgrades de nós e manutenções de infraestrutura sem indisponibilidade para a aplicação.

### Consequências Negativas e Riscos (Débitos/Trade-offs Aceitos)
* **Complexidade Operacional e Infraestrutura:**  
  * *Risco:* Gerenciar um cluster distribuído exige monitoramento de nós, topologia de anel (*Gossip protocol*) e rotinas de reparo (*nodetool repair*).
  * *Mitigação:* Provisionar cluster inicial de 3 nós utilizando instâncias dedicadas com discos NVMe na nuvem, configurados via infraestrutura como código (IaC) e com suporte a ferramentas de automação como Cassandra Operator (K8s) ou ScyllaDB Manager.
* **Curva de Aprendizado em Modelagem (*Query-Driven*):**  
  * *Risco:* Desenvolvedores habituados ao SQL relacional podem tentar criar índices secundários ou usar `ALLOW FILTERING`, o que degrada severamente o Cassandra.
  * *Mitigação:* O time de arquitetura fornecerá um guia de modelagem CQL, workshops práticos e checklists rigorosos em Pull Requests.
* **Risco de Degradação por Tombstones:**  
  * *Risco:* Inserções de valores nulos ou deleções manuais geram marcadores *tombstones* que lentificam leituras.
  * *Mitigação:* O repositório de histórico operará estritamente como *Append-Only* (apenas comandos `INSERT`). Estornos e cancelamentos serão modelados como novas linhas de transação com valores negativos/compensatórios.

### Consequências Neutras
* Adoção do driver oficial DataStax CQL no backend PHP (`cassandra-php` ou cliente gRPC ScyllaDB) e inclusão dos serviços no container de injeção de dependências (PHP-DI).
* Ajuste no pipeline de observabilidade para coletar métricas de JVM e compactação de SSTables via Prometheus e Grafana.

---

## 5. Plano de Conformidade e Validação

1. **Testes Automatizados:** Implementar testes de integração utilizando **Testcontainers** para instanciar nós efêmeros de Cassandra durante o pipeline de CI/CD.
2. **Alertas de Observabilidade:**
   * Alerta crítico caso consultas varram mais de 500 tombstones por operação (`TombstoneOverwhelmingException`).
   * Alerta caso o tamanho de qualquer partição ultrapasse o limiar de 100MB.
   * Monitoramento contínuo da latência de leitura e escrita no percentil p99 (meta: < 15ms).
3. **Revisão de Código (Gate de Engenharia):** Nenhum script CQL poderá ser promovido a produção contendo a cláusula `ALLOW FILTERING` ou índices secundários sem aprovação formal do time de Arquitetura de Dados.
