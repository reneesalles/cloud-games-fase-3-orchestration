$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

# ---------------------------------------------------------------------
# Variáveis Globais (Carregadas dinamicamente do .env)
# ---------------------------------------------------------------------
$envFilePath = Join-Path $PSScriptRoot ".env"

if (Test-Path $envFilePath) {
    Write-Output "Carregando configurações do arquivo .env..."
    foreach ($line in Get-Content $envFilePath) {
        # Ignora linhas vazias ou comentadas com #
        if ($line -match '^\s*([^#][^=]+)\s*=\s*(.*)$') {
            $varName = $matches[1].Trim()
            $varValue = $matches[2].Trim()
            
            # Remove aspas duplas ou simples, caso você tenha colocado no .env sem querer
            $varValue = $varValue -replace '^"|"$', ''
            $varValue = $varValue -replace "^'|'$", ''
            
            # Cria a variável no PowerShell (ex: cria $env, $suffix, etc.)
            Set-Variable -Name $varName -Value $varValue
        }
    }
} else {
    Write-Error "Arquivo .env não encontrado na pasta! Crie um arquivo .env antes de rodar o script."
    exit
}

# ---------------------------------------------------------------------
# Variáveis Globais (Selecione este bloco e rode no terminal primeiro)
# ---------------------------------------------------------------------
# Nome do Resource Group (ex: rg-tc3-nett-v1-dev)
$rg="rg-$suffix-$env"

# Nome do Key Vault (ex: kv-tc3-nett-v1-dev)
$kvName="kv-$suffix-$env"
# URI do Key Vault, para facilitar a configuração das variáveis de ambiente no App Service e Functions (ex: https://kv-tc3-nett-v1-dev.vault.azure.net/)
$kvUri = "https://$kvName.vault.azure.net/"

# Nome do Application Insights (ex: appi-tc3-nett-v1-dev)
$appInsightsName="appi-$suffix-$env"
# Nome do Log Analytics Workspace (ex: log-tc3-nett-v1-dev)
$workspaceName="log-$suffix-$env"

# Nome do namespace do Service Bus (ex: sb-tc3-nett-v1-dev)
$sbName="sb-$suffix-$env"
# Definição da topologia de tópicos, assinaturas e filtros do Service Bus. A chave é o nome do tópico, o valor é um dicionário onde a chave é o nome da assinatura e o valor é uma lista dos eventos que aquela assinatura deve receber (use "*" para curinga, ou seja, receber todos os eventos daquele tópico)
$serviceBusTopology = @{
    "integration-events" = @{
        "audit-log-subscription" = @("*")
    }
    "user-events" = @{
        "catalog-subscription" = @(
            "user-updated"
        )
        "notification-subscription" = @(
            "user-registered", "user-email-confirmed", "user-password-reset-requested", "user-password-reseted", "user-invited", "user-account-activated", "user-updated", "user-deleted", "user-restored"
        )
    }
    "catalog-events" = @{
        "payment-subscription" = @(
            "order-created", "order-cancelation-requested", "order-refund-requested"
        )
        "notification-subscription" = @(
            "game-recommendations-generated", "promotion-recommendations-generated", 
            "order-paid", "order-canceled", "order-refunded", "order-failed",
            "games-added-to-user-library", "games-removed-from-user-library"
        )
    }
    "payment-events" = @{
        "catalog-subscription" = @(
            "payment-succeeded", "payment-failed", "cancelation-succeeded", "cancelation-failed", "refund-succeeded", "refund-failed"
        )
        "notification-subscription" = @(
            "payment-link-generated"
        )
    }
}

# Nome da conta do Cosmos DB (ex: cosmos-tc3-nett-v1-dev)
$cosmosName="cosmos-$suffix-$env"

# Nome do servidor SQL (ex: sql-tc3-nett-v1-dev)
$sqlServerName="sql-$suffix-$env"

# Nome do Azure Container Registry (ex: acrfcgtc3nettv1dev)
$acrName = "acrfcg$suffixTrimmed$env" # ACR não aceita hífens

# Nome do App Service Plan (ex: plan-tc3-nett-v1-dev)
$appPlanName = "plan-$suffix-$env"
# Nome público da sua API (ex: app-fcg-gateway-tc3-nett-v1-dev)
$webAppName = "app-fcg-gateway-$suffix-$env"

# Nome da Function App para Audits (ex: func-audits-tc3-nett-v1-dev)
$funcAuditsName = "func-audits-$suffix-$env"
# Nome da Function App para Notifications (ex: func-notifications-tc3-nett-v1-dev)
$funcNotificationsName = "func-notifications-$suffix-$env"
# Nome da Function App para Payments (ex: func-payments-tc3-nett-v1-dev)
$funcPaymentsName = "func-payments-$suffix-$env"

# ---------------------------------------------------------------------
# 0. Registrar os namespaces necessários (às vezes dá erro de "Resource provider not found" se não tiver)
# ---------------------------------------------------------------------
# Garante que o namespace do Key Vault está registrado
az provider register --namespace Microsoft.KeyVault

# Garante que o namespace do Log Analytics está registrado
az feature register --name AIWorkspacePreview --namespace microsoft.insights
az provider register --namespace microsoft.insights

# Garante que o namespace do Alerts Management está registrado
az provider register --namespace Microsoft.AlertsManagement

# Garante que o namespace do Cosmos DB está registrado
az provider register --namespace Microsoft.DocumentDB

# Garante que o namespace do Container Registry está registrado
az provider register --namespace Microsoft.ContainerRegistry

# Pausa para garantir que os namespaces foram registrados antes de criar os recursos
Start-Sleep -Seconds 120

Write-Output "Iniciando provisionamento da infraestrutura para o ambiente: $env"

# ---------------------------------------------------------------------
# 1. Resource Group, Key Vault e Storage Account
# ---------------------------------------------------------------------
# Cria o Resource Group
Write-Output "Criando Resource Group: $rg"
az group create -n $rg -l $location

# Cria o Key Vault (O seu usuário que está logado no az CLI ganha permissão de admin automaticamente)
Write-Output "Criando Key Vault: $kvName"
az keyvault create -n $kvName -g $rg -l $location

# Atribuir permissões de RBAC para o usuário logado no az CLI acessar os segredos do Key Vault (Recomendado para desenvolvimento, em produção o ideal é usar Managed Identities)
Write-Host "Atribuindo permissões de RBAC ao seu usuário logado..."
$kvResourceId = az keyvault show -n $kvName -g $rg --query id -o tsv
$userId = az ad signed-in-user show --query id -o tsv

az role assignment create --role "Key Vault Secrets Officer" --assignee-object-id $userId --assignee-principal-type User --scope $kvResourceId

Write-Host "Aguardando 60 segundos para o Azure propagar a permissão globalmente..."
Start-Sleep -Seconds 60 # Pausa obrigatória para o RBAC funcionar

# Cria a Storage Account (necessária para o Application Insights e para o Azure Functions)
$sufixo = Get-Random -Minimum 1000 -Maximum 9999
$storageName = "stacccloudgames$sufixo"
Write-Output "Criando Storage Account: $storageName"
az storage account create -n $storageName -g $rg -l $location --sku Standard_LRS

# Salva a Connection String da Storage Account no Key Vault
Write-Output "Salvando Connection String da Storage Account no Key Vault"
$connectionString=$(az storage account show-connection-string -n $storageName -g $rg --query connectionString -o tsv)
az keyvault secret set --vault-name $kvName -n "StorageAccountConnection" --value "$connectionString"

# ---------------------------------------------------------------------
# 2. Observabilidade
# ---------------------------------------------------------------------
Write-Output "Configurando Observabilidade com Application Insights e Log Analytics"

Write-Output "Criando Log Analytics Workspace: $workspaceName"
az monitor log-analytics workspace create -g $rg -n $workspaceName --location $location
$workspaceId=$(az monitor log-analytics workspace show -g $rg -n $workspaceName --query id -o tsv)

Write-Output "Criando Application Insights: $appInsightsName"
az monitor app-insights component create -g $rg --app $appInsightsName --location $location --workspace $workspaceId

Write-Output "Salvando Connection String do Application Insights no Key Vault"
$appInsightsKey=$(az monitor app-insights component show -g $rg --app $appInsightsName --query connectionString -o tsv)
az keyvault secret set --vault-name $kvName -n "AppInsightsConnection" --value "$appInsightsKey"

# ---------------------------------------------------------------------
# 3. Mensageria (Service Bus Standard)
# ---------------------------------------------------------------------
Write-Output "Criando Service Bus Namespace: $sbName"
az servicebus namespace create -g $rg -n $sbName --location $location --sku Standard

Write-Output "Salvando Connection String do Service Bus no Key Vault"
$sbKey=$(az servicebus namespace authorization-rule keys list -g $rg --namespace-name $sbName -n RootManageSharedAccessKey --query primaryConnectionString -o tsv)
az keyvault secret set --vault-name $kvName -n "ServiceBusConnection" --value "$sbKey"

Write-Output "Criando Tópicos e Assinaturas no Service Bus com base na topologia definida..."
foreach ($topic in $serviceBusTopology.GetEnumerator()) {
    $topicName = $topic.Name
    $subscriptions = $topic.Value

    Write-Output "Criando Tópico: $topicName"
    az servicebus topic create -g $rg --namespace-name $sbName -n $topicName

    foreach ($sub in $subscriptions.GetEnumerator()) {
        $subName = $sub.Name
        $eventsList = $sub.Value

        Write-Output " -> Criando Assinatura: $subName"
        az servicebus topic subscription create -g $rg --namespace-name $sbName --topic-name $topicName -n $subName

        # Lógica de Filtro SQL
        if ($eventsList -contains "*") {
            Write-Output "    -> Regra curinga detectada. Mantendo filtro `$Default (1=1)."
        } else {
            # Converte o array do PowerShell ("a", "b") para formato SQL ('a', 'b')
            $sqlFormattedValues = ($eventsList | ForEach-Object { "'$_'" }) -join ", "
            $sqlExpression = "EventType IN ($sqlFormattedValues)"
            $ruleName = "Filtro-$subName"

            Write-Output "    -> Aplicando filtro SQL: $sqlExpression"
            
            # Cria a regra restritiva com o filtro SQL (que só deixa passar os eventos listados)
            az servicebus topic subscription rule create `
                -g $rg --namespace-name $sbName --topic-name $topicName --subscription-name $subName `
                --name $ruleName `
                --filter-sql-expression $sqlExpression 

            # Remove a regra padrão que deixaria passar todos os eventos
            Write-Output "    -> Removendo regra `$Default"
            az servicebus topic subscription rule delete `
                -g $rg --namespace-name $sbName --topic-name $topicName --subscription-name $subName `
                --name "`$Default"
        }
    }
}

# ---------------------------------------------------------------------
# 4. Cosmos DB (Serverless)
# ---------------------------------------------------------------------
Write-Output "Criando Cosmos DB Account: $cosmosName"
az cosmosdb create -g $rg -n $cosmosName --capabilities EnableServerless --default-consistency-level Session --locations regionName=$location failoverPriority=0 isZoneRedundant=False

Write-Output "Criando banco de dados no Cosmos DB: $cosmosDbName"
az cosmosdb sql database create -g $rg --account-name $cosmosName --name $cosmosDbName
az keyvault secret set --vault-name $kvName -n "CosmosDbName" --value "$cosmosDbName"

Write-Output "Criando container no Cosmos DB: $cosmosContainerName com partition key $cosmosPartitionKey"
az cosmosdb sql container create -g $rg --account-name $cosmosName --database-name $cosmosDbName --name $cosmosContainerName --partition-key-path $cosmosPartitionKey
az keyvault secret set --vault-name $kvName -n "CosmosDbContainer" --value "$cosmosContainerName"

Write-Output "Salvando Connection String do Cosmos DB no Key Vault"
$cosmosKey=$(az cosmosdb keys list -g $rg -n $cosmosName --type keys --query primaryMasterKey -o tsv)
$cosmosConnStr="AccountEndpoint=https://$cosmosName.documents.azure.com:443/;AccountKey=$cosmosKey;"
az keyvault secret set --vault-name $kvName -n "CosmosDbConnection" --value "$cosmosConnStr"

# ---------------------------------------------------------------------
# 5. SQL Server e Databases
# ---------------------------------------------------------------------
Write-Output "Criando SQL Server: $sqlServerName"
az sql server create -g $rg -n $sqlServerName --location $sqlLocation --admin-user $sqlAdmin --admin-password "$sqlPassword"
az sql server firewall-rule create -g $rg --server $sqlServerName -n AllowAll --start-ip-address 0.0.0.0 --end-ip-address 255.255.255.255

Write-Output "Criando SQL Databases: tc-fase-3-users-db, tc-fase-3-catalogs-db, tc-fase-3-payments-db"
az sql db create -g $rg --server $sqlServerName --name "tc-fase-3-users-db" --service-objective Basic
az sql db create -g $rg --server $sqlServerName --name "tc-fase-3-catalogs-db" --service-objective Basic
az sql db create -g $rg --server $sqlServerName --name "tc-fase-3-payments-db" --service-objective Basic

# Monta as strings de conexão e salva no Key Vault
Write-Output "Salvando Connection Strings do SQL Server no Key Vault"
$sqlBaseConn="Server=tcp:$sqlServerName.database.windows.net,1433;Persist Security Info=False;User ID=$sqlAdmin;Password=$sqlPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

az keyvault secret set --vault-name $kvName -n "SqlUsersConnection" --value "$sqlBaseConn Initial Catalog=tc-fase-3-users-db;"
az keyvault secret set --vault-name $kvName -n "SqlCatalogsConnection" --value "$sqlBaseConn Initial Catalog=tc-fase-3-catalogs-db;"
az keyvault secret set --vault-name $kvName -n "SqlPaymentsConnection" --value "$sqlBaseConn Initial Catalog=tc-fase-3-payments-db;"

Write-Output "Infraestrutura provisionada e segredos guardados no Key Vault: $kvName"

# ---------------------------------------------------------------------
# 6. Outras variáveis de ambiente
# ---------------------------------------------------------------------
Write-Output "Salvando variáveis JWT no Key Vault"
az keyvault secret set --vault-name $kvName -n "Jwt--Secret" --value "$jwtSecret"
az keyvault secret set --vault-name $kvName -n "Jwt--Issuer" --value "$jwtIssuer"
az keyvault secret set --vault-name $kvName -n "Jwt--ExpiryMinutes" --value "$jwtExpiryMinutes"
az keyvault secret set --vault-name $kvName -n "Jwt--Audience" --value "$jwtAudience"

Write-Output "Salvando variáveis de configuração do usuário admin no Key Vault"
az keyvault secret set --vault-name $kvName -n "AdminUser--Name" --value "$adminUserName"
az keyvault secret set --vault-name $kvName -n "AdminUser--Email" --value "$adminUserEmail"
az keyvault secret set --vault-name $kvName -n "AdminUser--Password" --value "$adminUserPassword"

# ---------------------------------------------------------------------
# 7. Azure Container Registry (ACR)
# ---------------------------------------------------------------------
Write-Output "Criando Azure Container Registry (ACR): $acrName"
# Criamos SEM o admin-enabled. Acesso será estritamente via Identidade Gerenciada.
az acr create -g $rg -n $acrName --sku Basic
$acrId = az acr show -n $acrName -g $rg --query id -o tsv

# ---------------------------------------------------------------------
# 8. Hospedagem (App Service Multi-container) e Identidade
# ---------------------------------------------------------------------
Write-Output "Criando App Service Plan (Plano Linux): $appPlanName"
az appservice plan create -g $rg -n $appPlanName --is-linux --sku B2 --location $appServiceLocation

Write-Output "Criando Web App for Containers: $webAppName"
# Criamos o Web App apontando para uma imagem genérica por enquanto. 
# A sua pipeline de CI/CD fará o deploy real do docker-compose.yml depois!
az webapp create -g $rg -p $appPlanName -n $webAppName -i "mcr.microsoft.com/azuredocs/aci-helloworld"

Write-Output "Habilitando CI/CD para o Web App (para facilitar o deploy do docker-compose.yml via az CLI ou Azure DevOps)"
$cicdUrl = az webapp deployment container config -g $rg -n $webAppName --enable-cd true --query CI_CD_URL -o tsv
az acr webhook create --name "hookAppServiceToACR" --registry $acrName --resource-group $rg --actions push --uri $cicdUrl

Write-Output "Habilitando Managed Identity no Web App (Apenas para ACR Pull)..."
$webAppPrincipalId = az webapp identity assign -g $rg -n $webAppName --query principalId -o tsv

# Dá a permissão de "AcrPull" para a identidade gerenciar o pull de imagens
az role assignment create --role "AcrPull" --assignee-object-id $webAppPrincipalId --assignee-principal-type ServicePrincipal --scope $acrId

Write-Output "Criando Service Principal exclusivo para o runtime da API acessar o Key Vault..."
$spAppRuntimeName = "sp-webapp-runtime-$suffix-$env"
# Cria o SPN e captura a saída em formato JSON
$spAppRuntimeJson = az ad sp create-for-rbac --name $spAppRuntimeName --json-auth | ConvertFrom-Json

$appClientId = $spAppRuntimeJson.clientId
$appClientSecret = $spAppRuntimeJson.clientSecret
$appTenantId = $spAppRuntimeJson.tenantId

$appObjectId = az ad sp show --id $appClientId --query id -o tsv

Write-Output "Concedendo permissão (Key Vault Secrets User) para o Service Principal da API..."
az role assignment create --role "Key Vault Secrets User" --assignee-object-id $appObjectId --assignee-principal-type ServicePrincipal --scope $kvResourceId

Write-Host "Aguardando 60 segundos para o Azure propagar a permissão da Identidade..."
Start-Sleep -Seconds 60

Write-Output "Configurando o Web App para usar a Identidade Gerenciada ao puxar as imagens do ACR..."
az webapp config set -g $rg -n $webAppName --generic-configurations '{\"acrUseManagedIdentityCreds\": true}'

Write-Output "Configurando App Settings (Variáveis de Ambiente) no Web App..."
# Aqui é onde a mágica acontece! Estas variáveis vão substituir os ${VARIAVEL} no seu docker-compose.yml
az webapp config appsettings set -g $rg -n $webAppName --settings `
    AZURE_CLIENT_ID=$appClientId `
    AZURE_CLIENT_SECRET=$appClientSecret `
    AZURE_TENANT_ID=$appTenantId `
    ACR_NAME=$acrName `
    KEY_VAULT_URL=$kvUri `
    APP_INSIGHTS_CONNECTION=$appInsightsKey `
    JWT_SECRET=$jwtSecret `
    DOCS_USERNAME=$docsUsername `
    DOCS_PASSWORD=$docsPassword `
    PAYMENTS_FUNCTION_KEY="aguardando-function" `
    WEBSITES_ENABLE_APP_SERVICE_STORAGE=false `
    DOCKER_REGISTRY_SERVER_URL="https://$acrName.azurecr.io"

# Habilita o log de contêiner para facilitar o debug inicial (você pode acessar os logs pelo Azure Portal ou usando az webapp log tail)
az webapp log config -g $rg -n $webAppName --docker-container-logging filesystem

Write-Output "------------------------------------------------------"
Write-Output "🚀 INFRAESTRUTURA FINALIZADA COM SUCESSO!"
Write-Output "👉 O seu Gateway responderá em: https://$webAppName.azurewebsites.net"
Write-Output "------------------------------------------------------"

# ---------------------------------------------------------------------
# 9. Azure Functions e Identidade
# ---------------------------------------------------------------------
Write-Output "Criando Function App (Audit) com imagem pública dummy..."
az functionapp create --name $funcAuditsName --storage-account $storageName --resource-group $rg --plan $appPlanName --functions-version 4 --os-type Linux --image "mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated10.0"

Write-Output "Criando Function App (Notifications) com imagem pública dummy..."
az functionapp create --name $funcNotificationsName --storage-account $storageName --resource-group $rg --plan $appPlanName --functions-version 4 --os-type Linux --image "mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated10.0"

Write-Output "Criando Function App (Payments) com imagem pública dummy..."
az functionapp create --name $funcPaymentsName --storage-account $storageName --resource-group $rg --plan $appPlanName --functions-version 4 --os-type Linux --image "mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated10.0"

Write-Output "Habilitando Identidade Gerenciada nas Functions..."
$auditPrincipalId = az functionapp identity assign -g $rg -n $funcAuditsName --query principalId -o tsv
$notifPrincipalId = az functionapp identity assign -g $rg -n $funcNotificationsName --query principalId -o tsv
$paymentPrincipalId = az functionapp identity assign -g $rg -n $funcPaymentsName --query principalId -o tsv

Write-Output "Concedendo permissão (AcrPull) para as Functions puxarem imagens do ACR..."
az role assignment create --role "AcrPull" --assignee-object-id $auditPrincipalId --assignee-principal-type ServicePrincipal --scope $acrId
az role assignment create --role "AcrPull" --assignee-object-id $notifPrincipalId --assignee-principal-type ServicePrincipal --scope $acrId
az role assignment create --role "AcrPull" --assignee-object-id $paymentPrincipalId --assignee-principal-type ServicePrincipal --scope $acrId

Write-Output "Concedendo permissão (Key Vault Secrets User) para as Functions lerem os segredos..."
az role assignment create --role "Key Vault Secrets User" --assignee-object-id $auditPrincipalId --assignee-principal-type ServicePrincipal --scope $kvResourceId
az role assignment create --role "Key Vault Secrets User" --assignee-object-id $notifPrincipalId --assignee-principal-type ServicePrincipal --scope $kvResourceId
az role assignment create --role "Key Vault Secrets User" --assignee-object-id $paymentPrincipalId --assignee-principal-type ServicePrincipal --scope $kvResourceId

Write-Output "Configurando variáveis de ambiente nas Functions..."
az functionapp config appsettings set -g $rg -n $funcAuditsName --settings KEY_VAULT_URI=$kvUri
az functionapp config appsettings set -g $rg -n $funcNotificationsName --settings KEY_VAULT_URI=$kvUri
az functionapp config appsettings set -g $rg -n $funcPaymentsName --settings KEY_VAULT_URI=$kvUri

# ---------------------------------------------------------------------
# 10. Criar Service Principal para CI/CD (GitHub Actions)
# ---------------------------------------------------------------------
Write-Output "Criando Service Principal (Crachá) para o GitHub Actions..."

$spGithubName = "sp-github-actions-$suffix-$env"
# Pega o ID da sua assinatura atual automaticamente
$subId = az account show --query id -o tsv

# Cria o SPN e guarda o JSON do output na variável
$spGithubJson = az ad sp create-for-rbac --name $spGithubName --role contributor --scopes /subscriptions/$subId/resourceGroups/$rg --json-auth

# Exibe na tela com um alerta gigante
Write-Output "=================================================================="
Write-Output "⚠️ ATENÇÃO: COPIE O JSON ABAIXO PARA O GITHUB SECRETS ⚠️"
Write-Output "Ele NUNCA MAIS será exibido pelo Azure!"
Write-Output "=================================================================="
Write-Output $spGithubJson
Write-Output "=================================================================="

# Bônus: Salva em um arquivo local na sua máquina para não perder (adicione este arquivo no seu .gitignore!)
$spGithubJson | Out-File -FilePath "github-credentials.json" -Encoding utf8
Write-Output "O JSON também foi salvo no arquivo 'github-credentials.json' na pasta atual."