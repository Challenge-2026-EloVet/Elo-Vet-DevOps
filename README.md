# Elo Vet — DevOps Tools & Cloud Computing (Sprint 3)

Infraestrutura como código (Azure CLI) para publicar a API Java do projeto
**Elo Vet** ([Challenge-2026-EloVet/java-sprint3](https://github.com/Challenge-2026-EloVet/java-sprint3))
em um **Azure App Service**, com um **banco de dados PaaS (Azure Database for
PostgreSQL — Flexible Server)**, conforme a Opção 2 da entrega de Sprint 3
("Serviço de Aplicativo + Banco PaaS").

## 1. Descrição da solução

O Elo Vet é uma API backend (Spring Boot) que apoia clínicas veterinárias e
tutores no acompanhamento pós-consulta de pets: cadastro de pets e
veterinários, autenticação com JWT, e um fluxo de **planos de cuidado**
(checklist terapêutico com lembretes) que reduz o abandono de tratamento após
a consulta.

Esta entrega cobre a parte de **DevOps**: publicar essa API e seu banco de
dados na nuvem, com todos os recursos criados via **Azure CLI**, sem uso de
containers (App Service + Banco PaaS, conforme exigido).

## 2. Benefícios para o negócio

- **Handoff automatizado** entre veterinário e tutor: reduz retrabalho manual
  e falhas de comunicação pós-consulta.
- **Adesão ao tratamento**: o checklist com lembretes aumenta a chance do
  tutor seguir o plano de cuidados corretamente.
- **Escalabilidade sem operação de infraestrutura**: o App Service e o banco
  PaaS eliminam a necessidade de gerenciar servidores, patch de SO ou backup
  manual do banco.
- **Custo previsível**: plano de serviço e SKU do banco dimensionados para o
  cenário de demonstração/avaliação (facilmente escaláveis para produção).

## 3. Arquitetura

```
Desenvolvedor              Azure CLI (Cloud Shell)              Azure
──────────────             ──────────────────────    ─────────────────────────────
git clone java-sprint3  →  ./scripts/*.sh (ver §6) →   Resource Group rg-elovet-devops
                                                        ├── App Service Plan (Linux, B1)
                                                        │     └── Web App api-java-seurm-<RM>  (Java 21)
                                                        └── PostgreSQL Flexible Server elovet-postgres-<RM>
                                                              └── database "elovet"
```

- **App**: Azure App Service (Linux, `JAVA:21-java21`), sem containers.
- **Banco**: Azure Database for PostgreSQL — Flexible Server (PaaS).
- **Conexão**: variáveis de ambiente (`SPRING_DATASOURCE_URL/USERNAME/PASSWORD`)
  configuradas como *App Settings* do Web App — nunca hardcoded no código-fonte.
- **Autenticação**: segredo JWT (`API_SECURITY_TOKEN_SECRET`) gerado
  automaticamente (`openssl rand -base64 48`) pelo `03-create-webapp.sh` e
  configurado como *App Setting* — também nunca hardcoded.
- **Schema**: criado automaticamente pela aplicação (Flyway + Hibernate) na
  primeira subida. O DDL correspondente está documentado em
  [`script_bd.sql`](./script_bd.sql).

## 4. Pré-requisitos

- Azure CLI autenticado (`az login`) na assinatura correta.
- Acesso ao repositório da API: https://github.com/Challenge-2026-EloVet/java-sprint3
- Permissão de owner/contributor na assinatura para criar Resource Group,
  App Service e PostgreSQL Flexible Server.

## 5. Estrutura deste repositório

```
Elo-Vet-DevOps/
├── README.md                          (este arquivo)
├── script_bd.sql                      (DDL das tabelas do banco)
├── github-actions/
│   └── deploy-devops-sprint3.yml       (workflow pronto, testado, usado de fato no java-sprint3)
└── scripts/
    ├── criacao-Resorce-Group/
    │   └── Configuracao-iniciais.sh    (variáveis compartilhadas + cria o Resource Group)
    ├── AppsAzure/
    │   ├── 02-create-postgres.sh       (cria o banco PaaS)
    │   └── 03-create-webapp.sh         (cria o App Service e conecta no banco)
    ├── GitHubAcitions.sh                (opcional — copia o workflow pronto + busca o publish profile)
    └── RemovendoGroups.sh               (remove todos os recursos ao final)
```

## 6. Passo a passo — criação dos recursos (via Azure CLI)

Execute a partir do Cloud Shell (ou terminal local com Azure CLI logado),
rodando **um arquivo de cada vez**, nesta ordem:

```bash
git clone https://github.com/Challenge-2026-EloVet/Elo-Vet-DevOps.git
cd Elo-Vet-DevOps/scripts

chmod +x criacao-Resorce-Group/*.sh AppsAzure/*.sh GitHubAcitions.sh RemovendoGroups.sh

./criacao-Resorce-Group/Configuracao-iniciais.sh
./AppsAzure/02-create-postgres.sh   # vai pedir usuário/senha do admin do Postgres
./AppsAzure/03-create-webapp.sh     # vai pedir o MESMO usuário/senha do passo anterior
```

Ao final desses três passos, o Web App já está no ar em
`https://api-java-seurm-<RM>.azurewebsites.net`, mas ainda sem o artefato
`.jar` publicado.

### 6.1 Publicar o código (deploy)

**Opção A — CI/CD automático (GitHub Actions), 100% via CLI, reprodutível do zero:**

Pré-requisito: [GitHub CLI](https://cli.github.com/) instalado e autenticado
(`gh auth login`) — sem isso o script não consegue criar o Secret.

```bash
git clone https://github.com/Challenge-2026-EloVet/java-sprint3.git ~/java-sprint3

./GitHubAcitions.sh ~/java-sprint3
```

Esse script faz tudo sozinho, sem nenhum passo manual pelo site do GitHub:
1. Copia o workflow **já pronto e testado**
   ([`github-actions/deploy-devops-sprint3.yml`](./github-actions/deploy-devops-sprint3.yml),
   usando Gradle corretamente desde o início) para dentro do clone local do
   `java-sprint3`, em `.github/workflows/`;
2. Busca o *Publish Profile* do Web App via Azure CLI e já cria o Secret
   `AZURE_WEBAPP_PUBLISH_PROFILE_DEVOPS` no repositório, via `gh secret set`
   (o valor nunca aparece na tela).

Depois é só commitar e subir o workflow copiado:

```bash
cd ~/java-sprint3
git add .github/workflows/deploy-devops-sprint3.yml
git commit -m "ci: adiciona deploy automático para api-java-seurm-<RM>"
git push
```

O `push` já dispara o build + deploy automático no GitHub Actions. A partir
daí, qualquer novo push na branch `main` builda e publica sozinho.

**Opção B — Deploy manual (mais simples/rápido para uma demo pontual):**

```bash
git clone https://github.com/Challenge-2026-EloVet/java-sprint3.git
cd java-sprint3
chmod +x gradlew
./gradlew bootJar -x test
cd build/libs

az webapp deploy \
  --resource-group rg-elovet-devops \
  --name api-java-seurm-<RM> \
  --src-path ./elo-vet-api-0.0.1-SNAPSHOT.jar \
  --type jar
```

## 7. Como testar o CRUD (Pet e Veterinário)

As rotas exigem autenticação JWT. Primeiro registre e autentique um usuário
`ADMIN` (necessário para criar/alterar/excluir Pet e Veterinário):

```bash
BASE_URL="https://api-java-seurm-<RM>.azurewebsites.net"

# 1) Registrar um usuário ADMIN
curl -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"nomeUsuario":"admin1","email":"admin1@elovet.com","senha":"senhaForte123","tipoUsuario":"ADMIN"}'

# 2) Login (retorna { "token": "..." })
TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"nomeUsuario":"admin1","senha":"senhaForte123"}' | jq -r .token)

# 3) Criar (INSERT) um Pet
curl -X POST "$BASE_URL/pet" \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"nome":"Thor","especie":"Cachorro","raca":"Golden Retriever","sexo":"M","flagCastrado":true}'

# 4) Criar (INSERT) um Veterinário (idUsuario deve existir em users)
curl -X POST "$BASE_URL/veterinary" \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"idUsuario":1,"nomeCompleto":"Dra. Ana Silva","cpf":"12345678901","crmv":"CRMV-1001"}'

# 5) Consultar (SELECT)
curl -H "Authorization: Bearer $TOKEN" "$BASE_URL/pet"
curl -H "Authorization: Bearer $TOKEN" "$BASE_URL/veterinary"

# 6) Alterar (UPDATE) — troque {id} pelo id retornado na criação
curl -X PUT "$BASE_URL/pet/{id}" \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"nome":"Thor Jr","especie":"Cachorro","raca":"Golden Retriever","sexo":"M","flagCastrado":true}'

# 7) Excluir (DELETE)
curl -X DELETE "$BASE_URL/pet/{id}" -H "Authorization: Bearer $TOKEN"
```

## 8. Como conferir diretamente no banco (SELECT)

```bash
psql "host=elovet-postgres-<RM>.postgres.database.azure.com port=5432 \
  dbname=elovet user=<usuario_admin> sslmode=require" \
  -c "SELECT * FROM elo_pet;" -c "SELECT * FROM elo_veterinario;"
```

## 9. Segurança

- Nenhuma credencial fica no código-fonte ou nos scripts: usuário/senha do
  banco são digitados interativamente (`read -s`) e passados apenas como
  variável de ambiente do App Service.
- O firewall do PostgreSQL neste laboratório é aberto (`0.0.0.0-255.255.255.255`)
  apenas para viabilizar a correção/demo remota — recomenda-se restringir após
  a avaliação.
- Tokens JWT (`api.security.token.secret`) devem ser configurados como App
  Setting do Web App, nunca versionados.

**Nota sobre recriação**: se você apagar e recriar o Postgres com o mesmo
nome logo em seguida, o Azure pode recusar por um período de carência
("Specified server name is already used"). Se isso acontecer, basta ajustar
`POSTGRES_SERVER_NAME` em `Configuracao-iniciais.sh` (ex.: acrescentar `-2`)
e rodar de novo.

## 10. Limpeza dos recursos

```bash
./scripts/RemovendoGroups.sh
```

Remove o Resource Group `rg-elovet-devops` e tudo o que foi criado nele.
