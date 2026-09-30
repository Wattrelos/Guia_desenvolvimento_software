# UC_CLI_001 - Navegar no Catálogo & Categorias

## 📋 Informações do Caso de Uso

| Atributo | Detalhe |
| :--- | :--- |
| **Identificador** | `UC_CLI_001` |
| **Nome** | Navegar no Catálogo & Categorias |
| **Módulo** | Loja Virtual - Catálogo, Busca & Mídia |
| **Atores Primários** | Visitante (*Guest*), Cliente Logado (*Customer*) |
| **Atores Secundários** | Sistema Alpha Engine |
| **Tipo** | Condução / Navegação |
| **Frequência de Uso** | Muito Alta |
| **Rastreabilidade** | **RF:** [RF003](/docs/requirements/functional/functional_requirements.yaml) (Categorização produtos), [RF011](/docs/requirements/functional/functional_requirements.yaml) (Busca e filtros)<br>**RN:** [RN003](/docs/requirements/business_rules/business_rules.yaml) (Especificações técnicas por categoria)<br>**RNF:** [RNF001](/docs/requirements/non_functional/non_functional_requirements.yaml) (Interface intuitiva), [RNF002](/docs/requirements/non_functional/non_functional_requirements.yaml) (Desempenho e velocidade) |

---

## 1. 🎯 Descrição Sumária
Permite ao usuário (visitante anônimo ou cliente autenticado) explorar a árvore de departamentos e categorias de materiais de construção (ex: Pisos & Porcelanatos, Tintas, Hidráulica, Elétrica, Ferramentas), visualizando os produtos disponíveis organizados hierarquicamente com breadcrumbs, ordenação e paginação.

---

## 2. ⚡ Pré-Condições
1. O sistema deve estar operacional e acessível via navegador web.
2. Deve existir ao menos uma categoria ativa cadastrada com produtos vinculados no banco de dados.

---

## 3. ✅ Pós-Condições
- O usuário visualiza a vitrine de produtos da categoria selecionada com paginação, ordenação (menor preço, maior preço, mais populares) e opções de filtragem lateral.

---

## 4. 🚀 Gatilho (Trigger)
O usuário acessa a página inicial ou clica no menu superior de departamentos/categorias.

---

## 5. 🔄 Fluxo Principal (Caminho Feliz)

1. **Ator:** Acessa o portal e passa o cursor ou clica no menu principal de departamentos.
2. **Sistema:** Carrega a taxonomia multinível de categorias ativas (ex: *Construção Básica > Cimentos e Argamassas*) a partir do cache Redis.
3. **Ator:** Clica sobre a categoria desejada (ex: "Pisos e Revestimentos").
4. **Sistema:** Processa a URL amigável (`/category/pisos-e-revestimentos`), consulta os produtos ativos da categoria com ordenação padrão e renderiza a página de listagem contendo:
   - Caminho de navegação (*Breadcrumbs*);
   - Grade/Lista de produtos com foto, nome, SKU, preço à vista (com desconto no PIX), preço parcelado e badges promocionais;
   - Controles de paginação e seletor de ordenação.
5. **Ator:** Navega pelos cards de produtos ou avança as páginas de resultado.
6. **Sistema:** Atualiza a listagem de forma fluida. O caso de uso encerra com sucesso.

---

## 6. 🔀 Fluxos Alternativos

- **FA01 - Ordenação de Resultados:**
  1. No passo 4 do fluxo principal, o ator altera a ordenação (ex: "Menor Preço" ou "Mais Vendidos").
  2. O sistema reordena a consulta no banco/cache e atualiza a grade de produtos sem recarregar o cabeçalho.
- **FA02 - Navegação via Breadcrumb:**
  1. O ator clica em um nível superior no breadcrumb (ex: clica em "Construção Básica" dentro de "Argamassas").
  2. O sistema redireciona para a categoria pai selecionada.

---

## 7. ⚠️ Fluxos de Exceção

- **FE01 - Categoria Vazia (Sem Produtos Ativos):**
  1. O sistema identifica que não há produtos em estoque ou ativos vinculados à categoria.
  2. O sistema exibe uma mensagem amigável: *"No momento não há produtos disponíveis nesta categoria. Confira outros departamentos."* acompanhada de sugestões de categorias populares.
- **FE02 - Falha de Cache / Conexão:**
  1. O Redis fica temporariamente inacessível.
  2. O sistema aciona o *fallback* transparente para o banco de dados MySQL sem interromper a navegação do usuário.

---

## 8. 📜 Regras de Negócio Aplicadas

- **RN003 (Informações Técnicas por Categoria):** Cada departamento exibe filtros condizentes com os produtos nele agrupados (ex: voltagem para ferramentas, acabamento para pisos).
- **RN017 (Preço Varejo vs. Atacado):** Se o cliente for PJ autenticado, o sistema exibe os preços diferenciados de atacado na listagem.

---

## 9. 🖥️ Interface & Campos de Entrada/Saída

### Entradas:
- Clique na Categoria / Subcategoria (`category_id` ou `slug`).
- Opção de ordenação (`sort_by`: `price_asc`, `price_desc`, `name`, `rating`).
- Número da página (`page`).

### Saídas:
- Grade de produtos contendo imagem WebP, nome, código SKU, preço varejo/atacado, parcelas e botão "Ver Detalhes".
- Painel de filtros facetados à esquerda.
