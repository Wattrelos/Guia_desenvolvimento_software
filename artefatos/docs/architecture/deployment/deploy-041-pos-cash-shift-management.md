# 🚀 Deployment Plan: Deploy 041 - Gestão de Turno de Caixa

## 1. Informações Gerais
* **Data/Hora da Janela:** 30/09/2026 às 23:00h (Horário de menor movimento).
* **Autor/Responsável:** [Seu Nome/Time]
* **Impacto esperado:** Baixo (Interrupção momentânea da API de vendas durante o restart).
* **Tempo Estimado:** 15 minutos.

## 2. Pré-requisitos & Dependências
* [ ] Execução prévia do script de migração no MariaDB (`agsc_pos_shift` e `agsc_pos_cash_movement`).
* [ ] Backup do banco de dados de produção antes do início.
* [ ] Permissões de `root` ou `sudo` no servidor `/opt/alpha/`.

## 3. Checklist de Execução (Passo a Passo)
1. **[ ] Backup:** Rodar `mysqldump` da base atual.
2. **[ ] Banco de Dados:** Aplicar a migração SQL (MariaDB beta).
3. **[ ] Backend:** Copiar o binário release compilado para `/opt/alpha/api`.
4. **[ ] Frontend:** Sincronizar o arquivo `pos.html` em `/opt/alpha/public/`.
5. **[ ] Serviço:** Reiniciar o serviço via `systemctl restart alpha-api.service`.

## 4. Plano de Validação Pós-Implantação (Sanity Check)
* [ ] Verificar se o serviço está ativo: `systemctl status alpha-api.service`.
* [ ] Validar rotas de healthcheck ou realizar um `GET /api/v1/pos/shift/current`.
* [ ] Abrir o PDV no navegador e checar se o badge `#pos-shift-badge` renderiza (Caixa Fechado).

## 5. Plano de Rollback (Em caso de falha)
Se a validação falhar ou o sistema apresentar instabilidade crítica:
1. Parar o serviço: `systemctl stop alpha-api.service`.
2. Restaurar o binário anterior a partir do diretório de backup `/opt/alpha/backup/api_old`.
3. Reverter a migração do banco de dados (se necessário) ou restaurar o dump.
4. Restaurar o `pos.html` anterior.
5. Reiniciar o serviço e validar estabilidade.
