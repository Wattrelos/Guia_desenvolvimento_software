# Domain-Driven Design (DDD) - Boas Práticas

> No desenvolvimento de software, DDD significa Domain-Driven Design (Design Guiado pelo Domínio). Não se trata de uma tecnologia, biblioteca ou linguagem de programação, mas sim de uma filosofia e um conjunto de práticas de modelagem criadas por Eric Evans em 2003 para facilitar o desenvolvimento de sistemas complexos.

O objetivo central do DDD é fazer com que o desenho do software (sua arquitetura e código) seja um reflexo fiel das regras e processos do negócio (o domínio). Em vez de focar primeiro no banco de dados ou em ferramentas técnicas, a equipe foca em entender profundamente o problema que o cliente precisa resolver.

# Os 3 Pilares Principais do DDD

Para alinhar a tecnologia ao negócio, o DDD se apoia em conceitos fundamentais, divididos entre o mapeamento do negócio e a organização do código:

- 1. Modelagem Estratégica (O Negócio)
 
    - * Domínio: É a área, o problema ou a atividade central da empresa (ex: o domínio de um aplicativo como o Uber é o transporte/logística).
    - * Linguagem Ubíqua (Universal): É um vocabulário comum e preciso compartilhado por desenvolvedores e especialistas do negócio (Domain Experts). Termos como "Pedido", "Cliente" ou "Faturamento" devem significar exatamente a mesma coisa nas reuniões e nas linhas de código.
    - * Contextos Delimitados (Bounded Contexts): Sistemas grandes possuem divisões. Uma palavra pode mudar de sentido dependendo do contexto: a palavra "Produto" pode significar algo físico para o setor de Estoque, mas apenas um preço e uma foto para o setor de Marketing. O DDD separa essas fronteiras de responsabilidade explicitamente.

- 2. Modelagem Tática (Os Blocos de Construção no Código)

Quando os contextos e regras já estão claros, o DDD fornece padrões para organizar as classes e estruturas do código:
* Entidades (Entities): Objetos que possuem uma identidade única que se mantém ao longo do tempo (ex: um Cliente com seu CPF).
* Objetos de Valor (Value Objects): Objetos que não têm identidade própria e são definidos apenas por seus atributos (ex: um endereço ou uma cor).
* Agregados (Aggregates): Um grupo de entidades e objetos de valor que são tratados como uma única unidade para garantir que as regras de negócio sejam respeitadas.
* Repositórios (Repositories): Padrões usados para buscar e salvar os agregados no banco de dados.

Quando vale a pena usar?

O DDD é uma abordagem poderosa, mas adiciona complexidade ao desenvolvimento.
* Use se: O negócio for complexo, as regras mudarem constantemente ou a aplicação for de grande porte (como sistemas bancários, CRMs ou e-commerces robustos).
* Evite se: For um sistema simples de "CRUD" (apenas telas para salvar, ler, editar e deletar dados simples) ou projetos puramente técnicos onde não há regras de negócio envolvidas.
