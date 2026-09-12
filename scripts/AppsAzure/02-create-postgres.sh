# ==============================================================================
# Passo 2 — Criação do Banco de Dados PaaS (Azure Database for PostgreSQL)
# + database inicial + regra de firewall
# ==============================================================================
set -euo pipefail
cd "$(dirname "$0")"
source ../criacao-Resorce-Group/Configuracao-iniciais.sh

echo "=== Criação do PostgreSQL Flexible Server: $POSTGRES_SERVER_NAME ==="

if [[ $# -ge 2 ]]; then
  PG_ADMIN_USER="$1"
  PG_ADMIN_PASSWORD="$2"
else
  echo "Informe as credenciais do administrador do banco (serão usadas só nesta execução)."
  read -rp "Usuário admin do Postgres: " PG_ADMIN_USER
  read -rsp "Senha do admin do Postgres (mín. 8 caracteres, com maiúscula/minúscula/número): " PG_ADMIN_PASSWORD
  echo
  read -rsp "Confirme a senha: " PG_ADMIN_PASSWORD_CONFIRM
  echo

  if [[ "$PG_ADMIN_PASSWORD" != "$PG_ADMIN_PASSWORD_CONFIRM" ]]; then
    echo "As senhas não conferem. Execute o script novamente." >&2
    exit 1
  fi
fi

if az postgres flexible-server show \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$POSTGRES_SERVER_NAME" &>/dev/null; then
  echo ">> Servidor '$POSTGRES_SERVER_NAME' já existe — pulando criação."
else
  az postgres flexible-server create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$POSTGRES_SERVER_NAME" \
    --location "$LOCATION" \
    --admin-user "$PG_ADMIN_USER" \
    --admin-password "$PG_ADMIN_PASSWORD" \
    --sku-name "$POSTGRES_SKU" \
    --tier "$POSTGRES_TIER" \
    --version "$POSTGRES_VERSION" \
    --storage-size "$POSTGRES_STORAGE_GB" \
    --public-access 0.0.0.0-255.255.255.255 \
    --yes
fi

if az postgres flexible-server db show \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --server-name "$POSTGRES_SERVER_NAME" \
    --database-name "$POSTGRES_DB_NAME" &>/dev/null; then
  echo ">> Database '$POSTGRES_DB_NAME' já existe — pulando criação (idempotente)."
else
  echo ">> Criando a database '$POSTGRES_DB_NAME' dentro do servidor..."
  az postgres flexible-server db create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --server-name "$POSTGRES_SERVER_NAME" \
    --database-name "$POSTGRES_DB_NAME"
fi

echo
echo ">> Banco criado. Guarde estes dados para o próximo script (03-create-webapp.sh):"
echo "   Host:  ${POSTGRES_SERVER_NAME}.postgres.database.azure.com"
echo "   Banco: ${POSTGRES_DB_NAME}"
echo "   Usuário: ${PG_ADMIN_USER}"
echo "   (a senha não é reexibida por segurança — use a mesma no script 03)"

