#!/usr/bin/env bash
# ==============================================================================
# Script de Automação: Construção da Estrutura de Pastas (Target Architecture)
# Baseado em: docs/architecture/file_structure_diagram_future.puml
# Padrões: Clean Architecture, DDD Modular, ADR, PSR-4 e PSR-15
# ==============================================================================

set -euo pipefail

# Paleta de Cores para o Terminal
readonly COLOR_RESET=$'\033[0m'
readonly COLOR_BOLD=$'\033[1m'
readonly COLOR_GREEN=$'\033[32m'
readonly COLOR_BLUE=$'\033[34m'
readonly COLOR_CYAN=$'\033[36m'
readonly COLOR_YELLOW=$'\033[33m'
readonly COLOR_RED=$'\033[31m'

# Configurações Padrão
TARGET_DIR="."
DRY_RUN=false
CREATE_GITKEEP=true

# Contadores de Estatística
DIR_COUNT=0
FILE_COUNT=0

# Exibir Mensagem de Ajuda
show_help() {
    cat << EOF
${COLOR_BOLD}Uso:${COLOR_RESET} $(basename "$0") [OPÇÕES] [DIRETÓRIO_DESTINO]

${COLOR_CYAN}Descrição:${COLOR_RESET}
  Cria automaticamente a árvore de diretórios e arquivos modelo da arquitetura
  alvo (futura) do projeto Beta Engine SaaS com base nas melhores práticas
  da engenharia de software moderna (Clean Architecture, DDD e PSR-4).

${COLOR_CYAN}Opções:${COLOR_RESET}
  -d, --dry-run      Simula a criação sem gravar nada no disco.
  --no-gitkeep       Não cria arquivos .gitkeep em pastas vazias.
  -h, --help         Exibe esta mensagem de ajuda.

${COLOR_CYAN}Exemplos:${COLOR_RESET}
  $(basename "$0")                     # Cria a estrutura no diretório atual (.)
  $(basename "$0") /tmp/novo-projeto   # Cria a estrutura em /tmp/novo-projeto
  $(basename "$0") --dry-run           # Apenas simula e lista o que seria criado

EOF
}

# Parsing de Argumentos da Linha de Comando
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-gitkeep)
            CREATE_GITKEEP=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo -e "${COLOR_RED}Opção inválida: $1${COLOR_RESET}" >&2
            show_help
            exit 1
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

echo -e "${COLOR_BOLD}${COLOR_BLUE}==============================================================================${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_CYAN}🚀 Construtor de Estrutura Arquitetural - Beta Engine SaaS (Future Target)${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_BLUE}==============================================================================${COLOR_RESET}"
echo -e "📁 Diretório Alvo: ${COLOR_YELLOW}${TARGET_DIR}${COLOR_RESET}"
if [ "$DRY_RUN" = true ]; then
    echo -e "🔍 Modo: ${COLOR_YELLOW}DRY-RUN (Simulação - nada será gravado)${COLOR_RESET}"
fi
echo ""

# Função Utilitária para Criar Diretório
create_dir() {
    local dir_path="$TARGET_DIR/$1"
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${COLOR_CYAN}[DIR]${COLOR_RESET}  $1"
    else
        if [ ! -d "$dir_path" ]; then
            mkdir -p "$dir_path"
            echo -e "  ${COLOR_GREEN}✓ [DIR]${COLOR_RESET}  $1"
        else
            echo -e "  ${COLOR_YELLOW}• [EXISTE]${COLOR_RESET} $1"
        fi
        
        # Opcionalmente adiciona .gitkeep para pastas vazias serem rastreadas no Git
        if [ "$CREATE_GITKEEP" = true ]; then
            if [ -z "$(ls -A "$dir_path" 2>/dev/null)" ]; then
                touch "$dir_path/.gitkeep"
            fi
        fi
    fi
    DIR_COUNT=$((DIR_COUNT + 1))
}

# Função Utilitária para Criar Arquivo Modelo
create_file() {
    local file_path="$TARGET_DIR/$1"
    local initial_content="${2:-}"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${COLOR_BLUE}[FILE]${COLOR_RESET} $1"
    else
        local parent_dir
        parent_dir=$(dirname "$file_path")
        mkdir -p "$parent_dir"
        
        if [ ! -f "$file_path" ]; then
            if [ -n "$initial_content" ]; then
                echo "$initial_content" > "$file_path"
            else
                touch "$file_path"
            fi
            echo -e "  ${COLOR_GREEN}✓ [FILE]${COLOR_RESET} $1"
        else
            echo -e "  ${COLOR_YELLOW}• [EXISTE]${COLOR_RESET} $1"
        fi
    fi
    FILE_COUNT=$((FILE_COUNT + 1))
}

echo -e "${COLOR_BOLD}1. Criando Diretórios de Configuração e Rotas (Backend Config)...${COLOR_RESET}"
create_dir "backend/config/routes"

echo -e "\n${COLOR_BOLD}2. Criando Camada de Domínio (DDD Bounded Contexts)...${COLOR_RESET}"
create_dir "backend/src/Domain/Shared/Enums"
create_dir "backend/src/Domain/Shared/Events"
create_dir "backend/src/Domain/Shared/ValueObjects"

create_dir "backend/src/Domain/Catalog/Entities"
create_dir "backend/src/Domain/Catalog/Events"
create_dir "backend/src/Domain/Catalog/Repositories"

create_dir "backend/src/Domain/Customer/Entities"
create_dir "backend/src/Domain/Customer/Repositories"

create_dir "backend/src/Domain/Order/Entities"
create_dir "backend/src/Domain/Order/Aggregates"
create_dir "backend/src/Domain/Order/Repositories"

create_dir "backend/src/Domain/Cart/Entities"
create_dir "backend/src/Domain/Cart/Repositories"

create_dir "backend/src/Domain/POS/Entities"
create_dir "backend/src/Domain/POS/Repositories"

create_dir "backend/src/Domain/Procurement/Entities"
create_dir "backend/src/Domain/Procurement/Repositories"

create_dir "backend/src/Domain/Security/Entities"
create_dir "backend/src/Domain/Security/Repositories"

echo -e "\n${COLOR_BOLD}3. Criando Camada de Aplicação (Use Cases & DTOs)...${COLOR_RESET}"
create_dir "backend/src/Application/Common"
create_dir "backend/src/Application/Catalog/DTOs"
create_dir "backend/src/Application/Catalog/UseCases"
create_dir "backend/src/Application/Customer/DTOs"
create_dir "backend/src/Application/Customer/UseCases"
create_dir "backend/src/Application/Order/DTOs"
create_dir "backend/src/Application/Order/UseCases"
create_dir "backend/src/Application/POS/DTOs"
create_dir "backend/src/Application/POS/UseCases"

echo -e "\n${COLOR_BOLD}4. Criando Camada de Infraestrutura e Persistência...${COLOR_RESET}"
create_dir "backend/src/Infrastructure/Persistence/Connection"
create_dir "backend/src/Infrastructure/Persistence/QueryBuilder"
create_dir "backend/src/Infrastructure/Persistence/UnitOfWork"
create_dir "backend/src/Infrastructure/Persistence/Mappers"
create_dir "backend/src/Infrastructure/Persistence/Repositories"
create_dir "backend/src/Infrastructure/Cache"
create_dir "backend/src/Infrastructure/Messaging"
create_dir "backend/src/Infrastructure/Security"
create_dir "backend/src/Infrastructure/Gateways/Payments"
create_dir "backend/src/Infrastructure/Gateways/Shipping"
create_dir "backend/src/Infrastructure/Gateways/Fiscal"

echo -e "\n${COLOR_BOLD}5. Criando Camada HTTP (Middlewares, Responders e Controllers ADR)...${COLOR_RESET}"
create_dir "backend/src/Http/Middlewares"
create_dir "backend/src/Http/Responders"
create_dir "backend/src/Http/Controllers/Storefront"
create_dir "backend/src/Http/Controllers/Admin"
create_dir "backend/src/Http/Controllers/POS"
create_dir "backend/src/Http/Controllers/Api"

echo -e "\n${COLOR_BOLD}6. Criando Recursos, Templates Twig e Internacionalização (i18n)...${COLOR_RESET}"
create_dir "backend/resources/locales/en-gb"
create_dir "backend/resources/locales/es-es"
create_dir "backend/resources/locales/pt-br"

create_dir "backend/resources/views/components/atoms"
create_dir "backend/resources/views/components/molecules"
create_dir "backend/resources/views/components/organisms"
create_dir "backend/resources/views/layouts"

create_dir "backend/resources/views/storefront/catalog"
create_dir "backend/resources/views/storefront/checkout"
create_dir "backend/resources/views/storefront/customer"

create_dir "backend/resources/views/admin/catalog"
create_dir "backend/resources/views/admin/crm"
create_dir "backend/resources/views/admin/dashboard"
create_dir "backend/resources/views/admin/sales"
create_dir "backend/resources/views/admin/settings"

create_dir "backend/resources/views/pos/cashier"
create_dir "backend/resources/views/pos/sales-rep"

echo -e "\n${COLOR_BOLD}7. Criando Webroot Pública (public_html)...${COLOR_RESET}"
create_dir "public_html/assets/css"
create_dir "public_html/assets/js"
create_dir "public_html/assets/fonts"
create_dir "public_html/uploads"

echo -e "\n${COLOR_BOLD}8. Criando Pastas de Banco de Dados, Documentação e Scripts...${COLOR_RESET}"
create_dir "database/migrations"
create_dir "database/seeds"
create_dir "database/schemas"

create_dir "docs/architecture/adr"
create_dir "docs/architecture/deployment"
create_dir "docs/business"
create_dir "docs/database"
create_dir "docs/diagrams"
create_dir "docs/specs"
create_dir "docs/workflows"

create_dir "scripts/devops"
create_dir "scripts/workers"

echo -e "\n${COLOR_BOLD}9. Criando Estrutura da Pirâmide de Testes (PHPUnit)...${COLOR_RESET}"
create_dir "tests/Unit"
create_dir "tests/Integration"
create_dir "tests/Functional"
create_dir "tests/E2E"

echo -e "\n${COLOR_BOLD}10. Gerando Arquivos Modelo Estruturais...${COLOR_RESET}"
# Configurações de rotas modulares
create_file "backend/config/routes/admin.php" "<?php\n\ndeclare(strict_types=1);\n\n// Rotas do Painel Administrativo\n"
create_file "backend/config/routes/api.php" "<?php\n\ndeclare(strict_types=1);\n\n// Rotas RESTful da API v1\n"
create_file "backend/config/routes/pos.php" "<?php\n\ndeclare(strict_types=1);\n\n// Rotas do Ponto de Venda (PDV)\n"
create_file "backend/config/routes/storefront.php" "<?php\n\ndeclare(strict_types=1);\n\n// Rotas da Loja Virtual (E-commerce)\n"

# Arquivos de entrada e configuração do backend
create_file "backend/config/app.php" "<?php\n\ndeclare(strict_types=1);\n\nreturn [\n    'name' => 'Beta Engine SaaS',\n    'env'  => getenv('APP_ENV') ?: 'production',\n];\n"
create_file "backend/config/database.php" "<?php\n\ndeclare(strict_types=1);\n\n// Configuração de Conexão MySQL\n"
create_file "backend/config/dependencies.php" "<?php\n\ndeclare(strict_types=1);\n\n// Definições do Container de Injeção de Dependências (PHP-DI)\n"
create_file "backend/config/middleware.php" "<?php\n\ndeclare(strict_types=1);\n\n// Pipeline Global de Middlewares PSR-15\n"

# Webroot Front Controller
create_file "public_html/index.php" "<?php\n\ndeclare(strict_types=1);\n\n// Front Controller Único da Aplicação\n"
create_file "public_html/robots.txt" "User-agent: *\nDisallow:\n"

echo -e "\n${COLOR_BOLD}${COLOR_GREEN}==============================================================================${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_GREEN}✅ Estrutura criada com sucesso!${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_GREEN}==============================================================================${COLOR_RESET}"
echo -e "📊 Estatísticas:"
echo -e "   • Total de Diretórios Processados: ${COLOR_CYAN}${DIR_COUNT}${COLOR_RESET}"
echo -e "   • Total de Arquivos Modelo:        ${COLOR_CYAN}${FILE_COUNT}${COLOR_RESET}"
echo -e "\n${COLOR_YELLOW}Dica de Engenharia:${COLOR_RESET} Para mapear o namespace no Composer, adicione ao seu composer.json:"
echo -e "${COLOR_CYAN}\"autoload\": { \"psr-4\": { \"App\\\\\": \"backend/src/\" } }${COLOR_RESET}\n"
