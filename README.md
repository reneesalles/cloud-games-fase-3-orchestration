<h1>Tech Challenge - FIAP Cloud Games - 10NETT - Grupo 29 - Fase 3</h1>

<h2>Sobre o Projeto</h2>

Evolução do sistema FCG em microsserviços rodando localmente via Docker Compose e Kubernetes (Fase 2) para uma arquitetura serverless na nuvem.

Como provedor de nuvem, utilizamos a Microsoft Azure, aproveitando serviços como Azure Functions, Azure Cosmos DB, Azure Service Bus e Azure Key Vault para criar uma aplicação escalável, resiliente e orientada a eventos.

<h2>Arquitetura</h2>

|Projeto|Tipo|Repositório|Responsabilidade|
|---|---|---|---|
|Users|API|[cloud-games-fase-3-users](https://github.com/reneesalles/cloud-games-fase-3-users)|Gerenciamento de usuários, autenticação e autorização.|
|Catalog|API|[cloud-games-fase-3-catalog](https://github.com/reneesalles/cloud-games-fase-3-catalog)|Gerenciamento do catálogo de jogos, promoções, biblioteca e carrinho do usuário, e checkout.|
|Notifications|Azure Functions|[cloud-games-fase-3-notifications](https://github.com/reneesalles/cloud-games-fase-3-notifications)|Gerenciamento de notificações para os usuários, como promoções, atualizações de jogos, cadastro do usuário, status dos pedidos.|
|Payments|Azure Functions|[cloud-games-fase-3-payments](https://github.com/reneesalles/cloud-games-fase-3-payments)|Gerenciamento de pagamentos, integração com gateways de pagamento, processamento de transações e status dos pedidos.|
|Audit|Azure Functions|[cloud-games-fase-3-audit](https://github.com/reneesalles/cloud-games-fase-3-audit)|Gerenciamento de auditoria, registro de eventos e atividades do sistema para monitoramento e análise.|

<h2>Documentos</h2>

- [Instruções TC Fase 3](./docs/TC-NETT-FASE-3.md)
- Diagrama em Draw.io com a [Arquitetura Cloud](./docs/ARQUITETURA-CLOUD.drawio)

<h2>Scripts úteis</h2>

- Script de infraestrutura (Azure CLI) para criar recursos no Azure: [infraestrutura-azure](./scripts/azure-cli/orchestration.ps1)
> Certifique-se de criar/ajustar no arquivo `.env` as variáveis de ambiente no script conforme necessário antes de executá-lo.\
> Utilize o arquivo `.env.example` como referência para criar o arquivo `.env` com as variáveis de ambiente necessárias para a execução do script.
> 
- Script para gerar os dados de configuração do Azure Functions: [config-azure-functions](./scripts/azure-cli/config-functions.ps1)
> O script acima gera um json para colar no arquivo `local.settings.json` para rodar as Azure Functions localmente, utilizando as variáveis de ambiente definidas no script.\
> Certifique-se de ter executado o script de infraestrutura para criar os recursos no Azure e ter as variáveis de ambiente definidas corretamente antes de executar este script.

- Script para limpar recursos no Azure: [limpeza-azure](./scripts/azure-cli/kill.ps1)
> O script acima remove os recursos criados no Azure, como Azure Functions, Azure Cosmos DB, SQL Server, Azure Service Bus, Azure Key Vault. Certifique-se de criar/ajustar no arquivo `.env` as variáveis de ambiente no script conforme necessário antes de executá-lo.
