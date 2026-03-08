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
# Variáveis Globais (Devem ser iguais as do seu script de criação)
# ---------------------------------------------------------------------
$rg="rg-$suffix-$env"
$kvName="kv-$suffix-$env"

# ---------------------------------------------------------------------
# 1. Apagar todo o ambiente (O parâmetro --no-wait libera o seu terminal na hora)
# ---------------------------------------------------------------------
Write-Output "Iniciando a exclusão do Resource Group: $rg..."
az group delete -n $rg --yes --no-wait

# Aguarda um pouco para garantir que o comando de exclusão foi processado antes de tentar expurgar o Key Vault
Start-Sleep -Seconds 10
# ---------------------------------------------------------------------
# 2. Expurgar o Key Vault da Lixeira (Permite recriar o ambiente com o mesmo nome depois)
# ---------------------------------------------------------------------
Write-Output "Removendo o Key Vault '$kvName' do Soft Delete (Purge)..."
az keyvault purge -n $kvName

Write-Output "Comando de destruição enviado! O Azure terminará o serviço em background."