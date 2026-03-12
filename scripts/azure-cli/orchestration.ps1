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
$rg="rg-$suffix-$env"
$kvName="kv-$suffix-$env"
$sbName="sb-$suffix-$env"
$cosmosName="cosmos-$suffix-$env"
$sqlServerName="sql-$suffix-$env"
$appInsightsName="appi-$suffix-$env"
$workspaceName="log-$suffix-$env"
$cosmosName="cosmos-$suffix-$env"

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