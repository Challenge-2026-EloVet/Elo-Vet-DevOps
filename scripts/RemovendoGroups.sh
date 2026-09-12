# ==============================================================================
# Limpeza — remove TODOS os recursos criados para esta entrega
# ==============================================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./criacao-Resorce-Group/Configuracao-iniciais.sh

read -rp "Isso vai DELETAR o Resource Group '$RESOURCE_GROUP_NAME' e TUDO dentro dele. Digite 'sim' para confirmar: " CONFIRM
if [[ "$CONFIRM" != "sim" ]]; then
  echo "Cancelado."
  exit 0
fi

az group delete --name "$RESOURCE_GROUP_NAME" --yes --no-wait
echo ">> Exclusão de '$RESOURCE_GROUP_NAME' solicitada (--no-wait, roda em background)."
