# Passos para correr o Jenkins.

Correr o serviço docker-compose2 individualmente

Correr o ngrok para criar um novo ip exposto: ngrok http http://localhost:8080

# Passos para criar a pipeline

    Entrar no jenkins e instalar os seguintes plugins. Instalar os plugins pode ser problemática.
    Por vezes é necessário repetir as instalações várias vezes:

        - GitHub Integration Plugin
        - GitHub Plugin
        - Docker Pipeline Plugin

    Criar um freestyle project chamado teseMestrado no jenkins (localhost:8080).

    Adicionar o url do projeto, configurar o repositorio com credenciais de acesso.

    Selecionar "Github hook trigger for GITScm polling"

    Inserir a pipeline.sh no script de pipeline

## Webhook

    Criar um webhook no repositorio do github

    Colocar o Content Type como application/json

    Alterar o ip no webhook do github para este formato: https://hash.ngrok-free.app/github-webhook/

# Passos para inicializar a base de dados

## Depois de correr a pipeline, ou correr o docker-compose. Executar os seguintes comandos:

    docker cp ./datasets/ postgres_db:/tmp/datasets - Para copiar os datasets para dentro do container.

    docker exec -it postgres_db psql -U myuser -d mydatabase -f /tmp/datasets/init.sql - Para copiar os csvs para a base de dados SQL
    a correr dentro do container.


# NOTA IMPORTANTE

    Após realizar as configurações, não apagar os volumes do jenkins e da base de dados, pois isso fará perder todas as configurações do Jenkins e a base de dados.
    