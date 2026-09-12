#!/usr/bin/env bash
# ==============================================================================
# Passo 3 — Criação do App Service Plan + Web App (Java 21 / Linux) e
# configuração das variáveis de ambiente do Spring Boot (conexão com o banco)
# ==============================================================================
set -euo pipefail
cd "$(dirname "$0")"
source ../criacao-Resorce-Group/Configuracao-iniciais.sh

echo " Criação do Plano de Serviço + Web App: $WEBAPP_NAME "

az appservice plan create \
  --name "$APP_SERVICE_PLAN" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION" \
  --sku "$APP_SERVICE_SKU" \
  --is-linux

az webapp create \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --plan "$APP_SERVICE_PLAN" \
  --runtime "$RUNTIME"

echo " Habilitando autenticação básica do SCM (necessária para deploy via CLI/GitHub Actions)"
az resource update \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --namespace Microsoft.Web \
  --resource-type basicPublishingCredentialsPolicies \
  --name scm \
  --parent "sites/$WEBAPP_NAME" \
  --set properties.allow=true

echo
echo "Configurando a conexão com o banco (variáveis de ambiente do Spring)"
if [[ $# -ge 2 ]]; then
  PG_ADMIN_USER="$1"
  PG_ADMIN_PASSWORD="$2"
else
  echo "Informe o MESMO usuário/senha criados no script 02-create-postgres.sh."
  read -rp "Usuário admin do Postgres: " PG_ADMIN_USER
  read -rsp "Senha do admin do Postgres: " PG_ADMIN_PASSWORD
  echo
fi

SPRING_DATASOURCE_URL="jdbc:postgresql://${POSTGRES_SERVER_NAME}.postgres.database.azure.com:5432/${POSTGRES_DB_NAME}?sslmode=require"

echo
echo "Gerando o segredo JWT "
if [[ $# -ge 3 ]]; then
  JWT_SECRET="$3"
else
  JWT_SECRET=$(openssl rand -base64 48)
  echo " Segredo gerado automaticamente"
fi

az webapp config appsettings set \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --settings \
    SPRING_DATASOURCE_URL="$SPRING_DATASOURCE_URL" \
    SPRING_DATASOURCE_USERNAME="$PG_ADMIN_USER" \
    SPRING_DATASOURCE_PASSWORD="$PG_ADMIN_PASSWORD" \
    SPRING_JPA_HIBERNATE_DDL_AUTO="update" \
    SPRING_DOCKER_COMPOSE_ENABLED="false" \
    API_SECURITY_TOKEN_SECRET="$JWT_SECRET"

az webapp restart --name "$WEBAPP_NAME" --resource-group "$RESOURCE_GROUP_NAME"

echo
echo ">> Web App disponível em: https://${WEBAPP_NAME}.azurewebsites.net"
echo "   o deploy manual com: az webapp deploy --resource-group $RESOURCE_GROUP_NAME \\"
echo "     --name $WEBAPP_NAME --src-path ./build/libs/elo-vet-api-0.0.1-SNAPSHOT.jar --type jar"
