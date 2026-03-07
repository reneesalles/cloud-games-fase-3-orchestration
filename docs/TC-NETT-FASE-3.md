# POS TECH

## Tech Challenge

Tech Challenge é o projeto da fase que engloba os conhecimentos obtidos em todas as disciplinas dela. Esta é uma atividade que, a princípio, deve ser desenvolvida em grupo. É importante atentar-se ao prazo de entrega, uma vez que essa atividade é obrigatória e vale 90% da nota de todas as disciplinas da fase.

### O problema

A FIAP Cloud Games (FCG) segue sua evolução! Nesta fase, o foco será a migração para microsserviços, a otimização da busca de jogos e a adoção de soluções serverless para eficiência operacional.

O desafio desta fase foi estruturado para aplicar os conhecimentos adquiridos nas disciplinas da fase, como Serverless, API Gateway, Microsserviços, Arquitetura de Software e Monitoramento e Acesso.


### O Desafio

Após a FIAP ter conseguido identificar o valor no MVP construído anteriormente e lançarmos a primeira versão para os alunos e alunas de forma totalmente automática e acessível via cloud, precisamos deixar nosso sistema mais robusto e modular, a fim de identificar problemas em módulos.

Sem deixarmos a aplicação totalmente fora do modelo anterior, no qual seguimos com a arquitetura monolítica, vamos dar robustez a ela e separar em módulos lógicos, garantindo a abordagem de microsserviços, além de seguirmos uma abordagem serverless, consolidando nossa escalabilidade.

---

## Funcionalidades Obrigatórias

### 1. Migração para Microsserviços:

*   Separar a API em três microsserviços principais. A seguir temos **exemplos** para a criação/separação de microsserviços:
    *   **Usuários**: cadastro, login e gerenciamento de perfis.
    *   **Jogos**: listagem, compra e recomendação de jogos.
    *   **Pagamentos**: processamento e status de transações.

### 2. Utilizar Serverless:

*   Criar funções serverless para processos assíncronos, como envio de notificações e processamento de pagamentos.
*   Configurar gatilhos em eventos para acionar funções de forma automática.
*   Implementar um API Gateway para gerenciar requisições dos microsserviços.
*   Garantir segurança entre os acessos para os microsserviços.

### 3. Arquitetura:

*   Implementar event sourcing ou equivalente como temporal tables, audit logs; algo que possa usar para registrar todas as mudanças no estado do sistema.
*   Melhorar a observabilidade com logs e rastreamento distribuído (Traces).

---

## Requisitos Técnicos

**Microsserviços:**

*   Criar ao menos três microsserviços, separados em repositórios diferentes. A seguir, uma sugestão para a separação (este é somente um exemplo; a forma com que ela será feita fica à sua escolha, mas é obrigatório que siga a separação em três microsserviços):
    *   Usuários.
    *   Jogos.
    *   Pagamentos.

**Serverless:**

*   Criar funções AWS Lambda ou Azure Functions (ou equivalente) para operações específicas.
*   Configurar triggers para acionar funções automaticamente.
*   Implementar API Gateway para gerenciar e proteger
os microsserviços.
*   **(Opcional)** Configurar a autenticação JWT e o controle de requisições.
*   **(Opcional)** Aplicar rate limiting para proteger os serviços contra sobrecarga.

**Arquitetura:**

*   Implementar event sourcing ou equivalente como temporal tables, audit logs; algo que possa usar para registrar todas as mudanças no estado do sistema.
*   Melhorar a observabilidade com logs e rastreamento distribuído (Traces).

---

## Entregáveis da Fase 3

*   **Vídeo de até 15 minutos demonstrando todos os requisitos**. 
    *   Ele pode ser em grupo ou individual (um integrante do grupo grava ou é possível se dividir entre si e apresentar).
    *   O projeto deve rodar na cloud (à sua escolha), apresentando os requisitos anteriores.
    *   Se o requisito técnico estiver com a flag **(Opcional)**, isso significa que caso ele não seja implementado não descontaremos pontos.
    *   A infraestrutura não precisa ficar em pé até a avaliação: após gravar o vídeo, ela deve ser excluída para evitar gastos. 

*   **Documentação (pode ficar no README/Miro/Imagem):**
    *   Fluxo de comunicação dos microsserviços.
    *   Desenho de arquitetura representando o fluxo de funcionamento.

*   **Código-fonte no repositório (público ou privado), incluindo:**
    *   APIs conforme requisitos separados em microsserviços.
    *   Arquivo de Pipeline CI (testes) escrita (fase anterior).
    *   Arquivo de Pipeline CD (deploy) escrita (fase anterior).
    *   Para o deploy da lambda, é possível utilizar Serverless Framework, CLI da cloud escolhida, terraform ou cloudformation.
    *   README.md completo com instruções de uso e objetivos.

*   **Relatório de entrega (PDF ou TXT):** esse arquivo deve ser postado na data da entrega e conter:
    *   Nome do grupo.
    *   Participantes e usernames no Discord.
    *   Link da documentação.
    *   Link dos repositórios.
    *   Link do vídeo salvo no Youtube ou lugar de sua preferência.

Lembramos que, caso você tenha qualquer dúvida, é só nos chamar no Discord!