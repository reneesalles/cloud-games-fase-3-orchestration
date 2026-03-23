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

# Nome público da sua API (ex: app-fcg-gateway-tc3-nett-v1-dev)
$webAppName = "app-fcg-gateway-$suffix-$env"

# ---------------------------------------------------------------------
# 1. Deploy do Container usando o docker-compose.yml na raiz do repositório
# ---------------------------------------------------------------------
# Resolve o caminho absoluto do docker-compose.yml garantindo que não importa de onde o script seja executado
$composePath = (Get-Item (Join-Path $PSScriptRoot "..\..\docker-compose.yml")).FullName

Write-Output "Iniciando o deploy do App Service com o arquivo:"
Write-Output $composePath

# Faz o deploy do container usando o docker-compose.yml
az webapp config container set -g $rg -n $webAppName --multicontainer-config-type compose --multicontainer-config-file $composePath

# Reinicia o App Service para aplicar as mudanças
az webapp restart -g $rg -n $webAppName