# ---------------------------------------------------------------------
# Script para criar a estrutura de projetos seguindo a arquitetura limpa (Clean Architecture)
# ---------------------------------------------------------------------

$location = "cloud-games-fase-3-catalog"
# $location = "cloud-games-fase-3-notifications"
# $location = "cloud-games-fase-3-payments"
# $location = "cloud-games-fase-3-users"

if (!(Test-Path -Path $location)) {
    Write-Output "Caminho '$location' não encontrado..."
    exit 1
}

Push-Location $location
$addFunction = $false
$addAPI = $true

try {    
    # ---------------------------------------------------------------------
    # Criar a estrutura de projetos
    # ---------------------------------------------------------------------

    # 1. Criar os arquivos de configuração pro projeto
    dotnet new globaljson --sdk-version 10.0.102
    dotnet new editorconfig
    dotnet new gitignore
    
    # 2. Criar a Solução com o nome padrão
    dotnet new sln -n Fiap.CloudGames
    
    # 3. Criar os projetos Core e Infra (Class Libraries)
    dotnet new classlib -n Fiap.CloudGames.Domain -f net10.0 -o src/Fiap.CloudGames.Domain
    dotnet new classlib -n Fiap.CloudGames.Application -f net10.0 -o src/Fiap.CloudGames.Application
    dotnet new classlib -n Fiap.CloudGames.Infrastructure -f net10.0 -o src/Fiap.CloudGames.Infrastructure
    
    # 4. Criar o projeto de presentation (escolher entre API ou Azure Functions, dependendo do cenário)
    if ($addFunction) {
        # 4.1 Criar o projeto Azure Functions (Isolated Worker no .NET 10)
        func init src/Fiap.CloudGames.Functions --worker-runtime dotnet-isolated --target-framework net10.0 --force
    }
    if ($addAPI) {
        #4.2 Criar o projeto API
        dotnet new webapi -n Fiap.CloudGames.API -f net10.0 -o src/Fiap.CloudGames.API
    }
    
    # 5. Adicionar todos os projetos à Solução .slnx
    dotnet sln Fiap.CloudGames.slnx add src/Fiap.CloudGames.Domain
    dotnet sln Fiap.CloudGames.slnx add src/Fiap.CloudGames.Application
    dotnet sln Fiap.CloudGames.slnx add src/Fiap.CloudGames.Infrastructure
    if ($addFunction) {
        dotnet sln Fiap.CloudGames.slnx add src/Fiap.CloudGames.Functions
    }
    if ($addAPI) {
        dotnet sln Fiap.CloudGames.slnx add src/Fiap.CloudGames.API
    }
    
    # 6. Configurar as referências de arquitetura (Inversão de Dependência)
    # 6.1 Application e Infrastructure conhecem APENAS o Domain
    dotnet add src/Fiap.CloudGames.Application reference src/Fiap.CloudGames.Domain
    dotnet add src/Fiap.CloudGames.Infrastructure reference src/Fiap.CloudGames.Domain
    if ($addFunction) {
        # 6.2 Presentation (Functions) amarra tudo: conhece App e Infra para configurar a Injeção de Dependência (DI) no Program.cs
        dotnet add src/Fiap.CloudGames.Functions reference src/Fiap.CloudGames.Application
        dotnet add src/Fiap.CloudGames.Functions reference src/Fiap.CloudGames.Domain
        dotnet add src/Fiap.CloudGames.Functions reference src/Fiap.CloudGames.Infrastructure
    }
    if ($addAPI) {
        # 6.3 Presentation (API) amarra tudo: conhece App e Infra para configurar a Injeção de Dependência (DI) no Program.cs
        dotnet add src/Fiap.CloudGames.API reference src/Fiap.CloudGames.Application
        dotnet add src/Fiap.CloudGames.API reference src/Fiap.CloudGames.Domain
        dotnet add src/Fiap.CloudGames.API reference src/Fiap.CloudGames.Infrastructure
    }
    
    # ---------------------------------------------------------------------
    # Criar o projeto de testes unitários
    # ---------------------------------------------------------------------
    
    # 1. Criar o projeto de testes usando xUnit (o padrão mais moderno no .NET)
    dotnet new xunit -n Fiap.CloudGames.UnitTests -f net10.0 -o tests/Fiap.CloudGames.UnitTests
    
    # 2. Adicionar o projeto à Solução
    dotnet sln Fiap.CloudGames.slnx add tests/Fiap.CloudGames.UnitTests
    
    # 3. Adicionar as referências de arquitetura (Testes conhecem a Aplicação e o Domínio)
    dotnet add tests/Fiap.CloudGames.UnitTests reference src/Fiap.CloudGames.Application
    dotnet add tests/Fiap.CloudGames.UnitTests reference src/Fiap.CloudGames.Domain
    
    # 4. Instalar o pacote do NSubstitute para a criação dos Mocks
    dotnet add tests/Fiap.CloudGames.UnitTests package NSubstitute
}
finally {
    Pop-Location
}