#!/usr/bin/env bash
# ==============================================================================
# Elo Vet — Sprint 3 (DevOps Tools & Cloud Computing)
# Configuração compartilhada por todos os scripts + Passo 1 (Resource Group).
# ==============================================================================

RM="565421"
LOCATION="canadacentral"

RESOURCE_GROUP_NAME="rg-elovet-devops"

# --- Banco de Dados (PostgreSQL| PaaS) ---
POSTGRES_SERVER_NAME="elovet-postgres-${RM}"
POSTGRES_DB_NAME="elovet"
POSTGRES_SKU="Standard_B1ms"
POSTGRES_TIER="Burstable"
POSTGRES_VERSION="14"
POSTGRES_STORAGE_GB="32"

# API Java
APP_SERVICE_PLAN="plan-elovet-devops"
APP_SERVICE_SKU="B1"
WEBAPP_NAME="api-java-seurm-${RM}"
RUNTIME="JAVA:21-java21"

# (GitHub Actions) 
GITHUB_REPO_NAME="Challenge-2026-EloVet/java-sprint3"
BRANCH="main"

# Passo 1 — Registro de providers + criação do Resource Group
set -euo pipefail

echo ">> Registrando os providers necessários no Azure (idempotente)"
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.DBforPostgreSQL

echo ">> Criando Resource Group '$RESOURCE_GROUP_NAME' em '$LOCATION'"
az group create \
  --name "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION"

echo ">> Resource Group pronto."
