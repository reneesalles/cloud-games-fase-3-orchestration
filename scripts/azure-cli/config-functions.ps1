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
$kvName="kv-$suffix-$env"

Write-Output "Montando os parâmetros do local.settings.json para debug local..."

# Extrai os valores reais do Azure Key Vault
$realStorageConn = az keyvault secret show --vault-name $kvName -n "StorageAccountConnection" --query value -o tsv
$realSbConn = az keyvault secret show --vault-name $kvName -n "ServiceBusConnection" --query value -o tsv
$realCosmosConn = az keyvault secret show --vault-name $kvName -n "CosmosDbConnection" --query value -o tsv
$realCosmosName = az keyvault secret show --vault-name $kvName -n "CosmosDbName" --query value -o tsv
$realCosmosContainer = az keyvault secret show --vault-name $kvName -n "CosmosDbContainer" --query value -o tsv

# Monta o objeto JSON
$localSettings = @{
    IsEncrypted = $false
    Values = @{
        FUNCTIONS_WORKER_RUNTIME = "dotnet-isolated"
        AzureWebJobsStorage = $realStorageConn
        ServiceBusConnection = $realSbConn
        CosmosDbConnection = $realCosmosConn
        CosmosDbName = $realCosmosName
        CosmosDbContainer = $realCosmosContainer
    }
}

# Converte o objeto para uma string JSON bem formatada
$jsonOutput = $localSettings | ConvertTo-Json -Depth 3

# Imprime no console chamando a atenção do desenvolvedor
Write-Host ""
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host " ATENÇÃO: COPIE O CONTEÚDO ABAIXO E COLE NO SEU local.settings.json" -ForegroundColor Yellow
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Output $jsonOutput
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""