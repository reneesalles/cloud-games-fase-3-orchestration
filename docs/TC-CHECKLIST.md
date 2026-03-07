# Checklist para a Fase 3 - TC-NETT

## Funcionalidades Obrigatórias

1. Microsserviços:
   - [x] Separar a API em três microsserviços principais (por exemplo: Usuários, Jogos, Pagamentos).
     - Já implementado nas fases anteriores
   - Fluxos de Usuário:
     - [x] Fluxo de Cadastro de Usuário
        - Já implementado nas fases anteriores
     - [~] Fluxo de Login e Autenticação
        - Já implementado nas fases anteriores, mas pode ser revisado durante a implementação de API Gateway
     - [x] Fluxo de Gerenciamento de Usuários/Perfis
        - Já implementado nas fases anteriores
   - Fluxos de Jogo:
     - [x] Fluxo de Listagem de Jogos
        - Já implementado nas fases anteriores
     - [~] Fluxo de Compra de Jogo
        - Já implementado nas fases anteriores, mas pode ser revisado durante a implementação de funções serverless
     - [ ] Fluxo de Recomendações de Jogos
   - Fluxos de Pagamento:
     - [~] Fluxo de Processamento de Pagamento
       - Já implementado nas fases anteriores, mas pode ser revisado durante a implementação de funções serverless
     - [~] Fluxo de Status de Transação
       - Já implementado nas fases anteriores, mas pode ser revisado durante a implementação de funções serverless

2. Serverless:
    - [ ] Criar funções serverless para processos assíncronos, como envio de notificações ou processamento de pagamentos.
    - [ ] Configurar gatilhos em eventos para acionar as funções serverless de forma automática.
    - [ ] Implementar um API Gateway para gerenciar as requisições dos microsserviços.
    - [ ] Garantir segurança entre os microsserviços.

3. Arquitetura:
    - [ ] Implementar event sourcing ou equivalente (como temporal tables, audit logs) para registrar todas as mudanças no estado do sistema.
    - [ ] Melhorar a observabilidade com logs e rastreamento distribuído (Traces).

---

## Requisitos Técnicos

1. Microsserviços:
   - [x] Criar ao menos três microsserviços, separados em repositórios diferentes (por exemplo: Usuários, Jogos, Pagamentos).
     - Já implementado nas fases anteriores, separando em:
       - Repositório de Usuários
         - Documentação do repositório
         - Arquivos de configuração para esse microsserviço em kubernetes
         - API para CRUD de usuários, autenticação e gerenciamento de perfis
       - Repositório de Catálogo de Jogos
         - Documentação do repositório
         - Arquivos de configuração para esse microsserviço em kubernetes
         - API para listagem, detalhes de jogos, e carrinho de compras
       - Repositório de Pagamentos
         - Documentação do repositório
         - Arquivos de configuração para esse microsserviço em kubernetes
         - Worker para processamento de transações, e API para receber postbacks dos status de pagamento (de um gateway de pagamento, por exemplo)
       - Repositório de Notificações
         - Documentação do repositório
         - Arquivos de configuração para esse microsserviço em kubernetes
         - Worker para envio de notificações por e-mail
       - Repositório de Orquestração
         - Documentação principal do projeto
         - Arquivos de configuração para orquestrar os microsserviços usando docker-compose
         - Arquivos de configuração para a infraestrutura em kubernetes

2. Serverless:
   - [ ] Criar funções AWS Lambda ou Azure Functions (ou equivalente) para operações específicas.
   - [ ] Configurar triggers para acionar funções automaticamente.
   - [ ] Implementar um API Gateway para gerenciar e proteger os microsserviços.
   - [ ] (Opcional) Configurar a autenticação JWT e o controle de requisições no API Gateway.
     - Tentar aproveitar a implementação de autenticação e controle de requisições já feita na fase anterior, integrando-a ao API Gateway.
   - [ ] (Opcional) Aplicar rate limiting para proteger os serviços contra sobrecarga.

3. Arquitetura:
   - [ ] Implementar event sourcing ou equivalente para registrar todas as mudanças no estado do sistema.
   - [ ] Melhorar a observabilidade com logs e rastreamento distribuído (Traces).
     - Na fase anterior foi implementado um monitoramento básico (usando grafana e loki), mas deve ser aprimorado.

---

## Entregáveis

1. Vídeo de Demonstração:
   - [ ] Criar um vídeo de até 15 minutos demonstrando as funcionalidades implementadas, o uso de serverless e arquitetura.
   - [ ] O projeto deve rodar na cloud (AWS, Azure, ou equivalente) e o vídeo deve mostrar a aplicação em funcionamento, destacando as funcionalidades implementadas e a arquitetura utilizada.
      > [!WARNING]
      > A infraestrutura não precisa ficar em pé até a avaliação: após gravar o vídeo, ela deve ser excluída para evitar gastos

2. Documentação (README, Miro, Imagem, etc):
   - [ ] Fluxo de comunicação dos microsserviços.
   - [ ] Desenho de arquitetura representando o fluxo de funcionamento.

3. Código-fonte:
   - [ ] APIs conforme requisitos separados em microsserviços.
   - [ ] Arquivo de Pipeline CI (testes) escrita (fase anterior).
   - [ ] Arquivo de Pipeline CD (deploy) escrita (fase anterior).
      > [!TIP]
      > Para o deploy da lambda, é possível utilizar Serverless Framework, CLI da cloud escolhida, terraform ou cloudformation
   - [ ] README.md completo com instruções de uso e objetivos.