# ==============================================================================
# Passo 4 (opcional) — CI/CD automático com GitHub Actions
# ==============================================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./criacao-Resorce-Group/Configuracao-iniciais.sh

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 /caminho/para/seu/clone/local/do/java-sprint3" >&2
  exit 1
fi

JAVA_SPRINT3_PATH="$1"

if [[ ! -d "$JAVA_SPRINT3_PATH/.git" ]]; then
  echo "ERRO: '$JAVA_SPRINT3_PATH' não parece ser um clone git do java-sprint3." >&2
  exit 1
fi

mkdir -p "$JAVA_SPRINT3_PATH/.github/workflows"
cp ../github-actions/deploy-devops-sprint3.yml "$JAVA_SPRINT3_PATH/.github/workflows/deploy-devops-sprint3.yml"
echo ">> Workflow copiado para: $JAVA_SPRINT3_PATH/.github/workflows/deploy-devops-sprint3.yml"

echo
echo "Criando o Secret no GitHub a partir do Publish Profile do Web App"
az webapp deployment list-publishing-profiles \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$WEBAPP_NAME" \
  --xml \
  | gh secret set AZURE_WEBAPP_PUBLISH_PROFILE_DEVOPS --repo "$GITHUB_REPO_NAME"

echo ">> Secret 'AZURE_WEBAPP_PUBLISH_PROFILE_DEVOPS' criado/atualizado em $GITHUB_REPO_NAME"
