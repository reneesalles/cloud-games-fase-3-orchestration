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

# Nome do Azure Container Registry (ex: acrfcgtc3nettv1dev)
$acrName = "acrfcg$suffixTrimmed$env"

# Nome público da sua API (ex: app-fcg-gateway-tc3-nett-v1-dev)
$webAppName = "app-fcg-gateway-$suffix-$env"

# ---------------------------------------------------------------------
# 1. Faz login no ACR, builda a imagem do APISIX e faz push
# ---------------------------------------------------------------------
Write-Output "Autenticando no Azure Container Registry: $acrName..."
az acr login --name $acrName

Write-Output "Fazendo o build da nova imagem do APISIX..."
$dockerfilePath = (Get-Item (Join-Path $PSScriptRoot "..\..\Dockerfile.apisix")).FullName
docker build -f $dockerfilePath -t "$acrName.azurecr.io/fcg-api-gateway:latest" .

Write-Output "Enviando a imagem para o ACR..."
docker push "$acrName.azurecr.io/fcg-api-gateway:latest"

Write-Output "Reiniciando o App Service para aplicar as mudanças..."
az webapp restart -g $rg -n $webAppName

Write-Output "✅ Deploy do APISIX concluído!"