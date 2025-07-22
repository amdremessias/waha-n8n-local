# waha-n8n-local
Este projeto configura um ambiente local para integração entre **WAHA** (WhatsApp HTTP API) e **n8n** (automação de workflows), utilizando **Redis** e **PostgreSQL** como bancos de dados. Tudo é orquestrado com **Docker Compose**, incluindo uma configuração de **SSL com certificado autoassinado** para o n8n, ideal para ambientes de rede local.
## 🚀 Visão Geral do Projeto
Este repositório contém os arquivos e scripts necessários para automatizar a implantação de um ambiente de desenvolvimento e testes para:
- **WAHA:** Uma API para integrar o WhatsApp em seus sistemas.
- **n8n:** Uma ferramenta de automação de código aberto para conectar APIs e serviços.
- **Redis:** Um armazenamento de dados em memória, usado como cache ou banco de dados.
- **PostgreSQL:** Um sistema de gerenciamento de banco de dados relacional.
A configuração inclui um **certificado SSL autoassinado** para o n8n, permitindo acesso HTTPS seguro dentro da sua rede local.
## 🛠️ Pré-requisitos
Para rodar este projeto, você precisará ter o **Docker** e o **Docker Compose** instalados em seu sistema.
### 1. Instalar Docker e Docker Compose
Utilize o script `install_docker_env.sh` para verificar e instalar as dependências automaticamente.

    Dê permissões de execução ao script:

    chmod +x install_docker_env.sh

    Execute o script como root:

    sudo ./install_docker_env.sh

    Este script irá instalar o Docker e o Docker Compose (se não estiverem presentes), solicitar as variáveis de ambiente para os serviços e criar o arquivo docker-compose.yml inicial.

🔑 Configuração de SSL (Certificado Autoassinado) para n8n
Para que o n8n funcione com HTTPS em sua rede local, você precisará de um certificado SSL. Como estamos em um ambiente local (IP privado ou host.docker.internal), usaremos um certificado autoassinado.
1. Ajuste do arquivo hosts
É IMPRESCINDÍVEL que o IP do seu servidor onde o Docker está rodando seja mapeado para um nome de host no arquivo hosts da máquina que acessará o n8n. Isso é crucial para que o certificado autoassinado seja validado corretamente.

    Windows: C:\Windows\System32\drivers\etc\hosts

    Linux/macOS: /etc/hosts

Exemplo:
192.168.2.47    host.docker.internal
Observação: Substitua 192.168.2.47 pelo endereço IP do seu servidor onde o Docker está rodando.
2. Gerar o Certificado SSL Autoassinado
Utilize o script generate_self_signed_ssl.sh para gerar os arquivos .crt (certificado) e .key (chave privada). Os arquivos serão salvos no diretório /opt/robot/ssl/n8n_ssl_local/.

    Dê permissões de execução ao script:

    chmod +x generate_self_signed_ssl.sh

    Execute o script como root:

    sudo ./generate_self_signed_ssl.sh

    Siga as instruções para fornecer o IP ou nome de host que você usará para acessar o n8n (ex: 192.168.2.47 ou host.docker.internal).

3. Configurar docker-compose.yml para SSL
Após gerar os certificados, você deve ajustar o arquivo docker-compose.yml para que o contêiner do n8n possa acessá-los e utilizá-los. Edite a seção n8n conforme o exemplo abaixo.
Atenção: Certifique-se de que os caminhos no volumes apontem para onde os arquivos foram gerados (/opt/robot/ssl/n8n_ssl_local/).
# docker-compose.yml (apenas a seção do n8n foi modificada)
services:
  # ... (outros serviços como redis, postgres, waha) ...

  n8n:
    image: n8nio/n8n:latest
    platform: linux/amd64
    environment:
      # ... (suas variáveis de ambiente existentes para n8n) ...
      # Altere WEBHOOK_URL e N8N_HOST para usar HTTPS e o IP/nome de host local
      WEBHOOK_URL: https://192.168.2.47:5678 # Use seu IP local ou o nome do host interno (deve corresponder ao CN do certificado)
      N8N_HOST: 192.168.2.47                  # Use seu IP local ou o nome do host interno (deve corresponder ao CN do certificado)
      GENERIC_TIMEZONE: America/Sao_Paulo
      N8N_LOG_LEVEL: debug
      N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE: "true"
      # Novas variáveis de ambiente para SSL:
      N8N_PROTOCOL: https
      N8N_SSL_CERT: /etc/ssl/n8n_local/n8n_local.crt # Caminho do certificado DENTRO do contêiner
      N8N_SSL_KEY: /etc/ssl/n8n_local/n8n_local.key   # Caminho da chave DENTRO do contêiner
    volumes:
      - n8n_data:/home/node/.n8n
      # Mapeamento dos certificados autoassinados do HOST para o contêiner:
      # Certifique-se de que o caminho do host esteja CORRETO para onde você gerou os arquivos!
      - /opt/robot/ssl/n8n_ssl_local/n8n_local.crt:/etc/ssl/n8n_local/n8n_local.crt:ro
      - /opt/robot/ssl/n8n_ssl_local/n8n_local.key:/etc/ssl/n8n_local/n8n_local.key:ro
    ports:
      - "5678:5678" # Porta para acesso HTTPS ao n8n
    # Certifique-se de que n8n_data, pgdata, waha_sessions e waha_media estão listados nos volumes globais

4. Reiniciar os Serviços Docker Compose
Após ajustar e salvar o arquivo docker-compose.yml, execute os comandos abaixo no diretório onde o docker-compose.yml está localizado:
# Para o container e remove os volumes anônimos (bom para "limpar" a execução anterior)
docker-compose down -v
# Levanta os serviços em segundo plano com as novas configurações
docker-compose up -d
🔒 Solução de Erro de Permissão (EACCES)
Caso você encontre o erro EACCES: permission denied, open '/etc/ssl/n8n_local/n8n_local.key', isso indica que o usuário do contêiner do n8n não tem permissão para ler o arquivo da chave privada no host.
Para resolver, ajuste as permissões dos arquivos e do diretório no seu servidor host (fora do Docker). Assumindo que o UID (User ID) do usuário node dentro do contêiner do n8n seja 1000:
# Exemplo: Mudar o proprietário do grupo para o GID 1000 e dar permissão de leitura ao grupo
# Substitua /opt/robot/ssl/n8n_ssl_local/ pelo caminho real dos seus certificados
sudo chown :1000 /opt/robot/ssl/n8n_ssl_local/n8n_local.key
sudo chown :1000 /opt/robot/ssl/n8n_ssl_local/n8n_local.crt
# Dê permissão de leitura para o proprietário e para o grupo (640)
sudo chmod 640 /opt/robot/ssl/n8n_ssl_local/n8n_local.key
sudo chmod 640 /opt/robot/ssl/n8n_ssl_local/n8n_local.crt

# (Opcional) Ajuste as permissões do diretório para que o grupo possa listar e navegar (750)
sudo chown :1000 /opt/robot/ssl/n8n_ssl_local/
sudo chmod 750 /opt/robot/ssl/n8n_ssl_local/

Após aplicar as permissões, reinicie o Docker Compose novamente.
🌐 Acessando o n8n com Certificado Autoassinado

Ao acessar o n8n via HTTPS (por exemplo, https://192.168.2.47:5678 ou https://host.docker.internal:5678) no seu navegador, você verá um aviso de segurança. Isso é esperado, pois o certificado é autoassinado e não é emitido por uma Autoridade Certificadora (CA) globalmente confiável.

Para prosseguir, você precisará aceitar o risco e adicionar uma exceção no seu navegador. Para evitar futuros avisos, você pode instalar o arquivo n8n_local.crt como um certificado de Autoridade de Certificação Confiável no seu sistema operacional ou navegador. O processo varia de acordo com o sistema (Windows, macOS, Linux) e o navegador que você utiliza.
__________________________________________________________________________________________________________________________________________________________________________

Tutorial: Configuração de n8n e Webhook com Waha
Este guia irá auxiliá-lo na configuração do n8n para interagir com o Waha via webhooks. Para simplificar o ambiente de desenvolvimento local, desativaremos as variáveis SSL do n8n.

1. Configuração do n8n (Docker Compose)
Certifique-se de que as variáveis de ambiente do seu docker-compose.yml para o n8n estejam configuradas conforme abaixo. Note que estamos usando http e host.docker.internal para acesso local sem SSL neste exemplo.

YAML

n8n:
  image: n8nio/n8n:latest
  platform: linux/amd64
  environment:
    # ... (suas variáveis de ambiente existentes para n8n) ...
    WEBHOOK_URL: http://host.docker.internal:5678 # Use seu IP local ou o nome do host interno
    N8N_HOST: host.docker.internal              # Use seu IP local ou o nome do host interno
    GENERIC_TIMEZONE: America/Sao_Paulo
    N8N_LOG_LEVEL: debug
    N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE: "true"
    N8N_SECURE_COOKIE: "false" # Ignora conexões sem SSL
    # Novas variáveis de ambiente para SSL (comentadas, pois estão desativadas)
    # N8N_PROTOCOL: https
    # N8N_SSL_CERT: /etc/ssl/n8n_local/n8n_local.crt # Caminho do certificado dentro do contêiner
    # N8N_SSL_KEY: /etc/ssl/n8n_local/n8n_local.key   # Caminho da chave dentro do contêiner
  volumes:
    n8n_data:/home/node/.n8n
    # Mapeamento dos certificados autoassinados do host para o contêiner (comentado, pois SSL está desativado)
    # Certifique-se de que o caminho do host esteja correto para onde você gerou os arquivos!
    # /opt/robot/ssl/n8n_ssl_local/n8n_local.crt:/etc/ssl/n8n_local/n8n_local.crt:ro
    # /opt/robot/ssl/n8n_ssl_local/n8n_local.key:/etc/ssl/n8n_local/n8n_local.key:ro
2. Configuração do Workflow no n8n
Após iniciar o n8n, faça login e siga os passos para criar seu workflow:

2.1. Criar Webhook de Entrada
Crie um novo workflow e nomeie-o como desejar.

Clique no + para adicionar um passo e selecione "On webhook call".

Nas configurações do webhook:

Mude o método para POST.

Em Path, digite webhook. (Se você alterou esta variável no docker-compose.yml, ajuste aqui também).

Copie a URL gerada na parte superior.

Clique em "Listen for test event".

2.2. Configurar Webhook no Waha
Com a URL do n8n copiada, vá para o Waha.

Na conta do WhatsApp já conectada, clique em "Configurar" e depois no + para adicionar um novo webhook.

Cole a URL do n8n que você copiou.

Agora, envie uma mensagem de outro número de WhatsApp para o número que está vinculado no Waha.

No n8n, você verá várias informações serem recebidas. Clique no ícone de pino (canto superior direito do nó do webhook) para manter esses dados visíveis. Isso é crucial para os próximos passos.

2.3. Processar Dados com "Set" (Edit Fields)
Com os dados "pinados", clique no + para adicionar um novo nó e pesquise por "Set" ou "Edit Fields".

Renomeie o nó para "Dados".

Clique no dropdown "Input" para expandir as configurações.

Configure os campos conforme o exemplo abaixo, arrastando os valores da esquerda (dos dados do webhook pinados) para o campo Value de cada Field que você criar:

session -> Arraste session de Body

chatid -> Arraste from de Payload

pushName -> Arraste PushName de _data

payload_id -> Arraste id de Payload

event -> Arraste event de Body

message -> Arraste body de Payload

fromMe -> Arraste fromMe de Payload

Clique em "Test" para visualizar as informações processadas na saída (direita).

Salve o workflow.

2.4. Adicionar Lógica Condicional com "Switch"
Adicione um nó "Switch".

Em "Routing Rules", arraste o elemento event da esquerda até esse campo.

No campo Value, digite message. Isso fará com que o workflow siga um caminho específico apenas para eventos de mensagem.

Salve o workflow.

2.5. Integrar com Agente de IA
Conecte a saída do nó "Switch" (para o caminho "message") a um novo nó. Pesquise por "AI Agent" e selecione-o.

Nas configurações do AI Agent:

Em "Source for Prompt", selecione Define below.

No campo abaixo, arraste o elemento message da esquerda para o centro.

Clique em "Add Option" e selecione "System Message".

Digite um breve texto para treinar seu bot. Exemplo: "Você é um atendente de loja de venda de rodas de carro de várias marcas."

No nó "AI Agent", clique no ícone + ao lado de "Chat Model":

Selecione o modelo de IA de sua escolha (ex: Gemini).

Após adicionar sua chave API, selecione o modelo (ex: models/gemini-pro).

Em "Add Options", você pode definir o nível de "lucidez" (temperature). O valor padrão de 0.4 costuma ser um bom ponto de partida.

Agora, clique no ícone + ao lado de "Memory":

Selecione "Redis Chat Memory".

Em "Credential to connect", preencha os campos:

password: (Deixe como default se não houver um definido no seu Redis)

user: (Deixe em branco se não houver um definido)

host: host.docker.internal

Salve.

Marque "Define Below" para "Session ID".

Em "Key", arraste o elemento chatid do nó "Dados" (da esquerda) para este campo.

Em "Session Time To live": 3600 (1 hora)

Em "Context Window Length": 10

Salve.

2.6. Enviar Confirmação de Leitura (Seen) com Waha
Conecte a saída do nó "AI Agent" a um novo nó "Waha".

Selecione a trigger "Send Seen".

Configure a conexão com a URL do Waha: http://host.docker.internal:3000.

Salve.

Clique em "Execute" no canto superior esquerdo.

Apague os valores dos campos no centro da tela abaixo de "POST Session | Chat | Message ID".

Arraste da esquerda para o centro os seguintes elementos:

session

chatid

payload_id

Salve.

2.7. Enviar Resposta do Bot com Waha
Por último, adicione mais uma trigger "Waha" e selecione "Send a text message".

Nas configurações, apague os valores de Session e Chat Id.

Arraste os elementos correspondentes do nó "Dados" (na esquerda) para os respectivos campos.

Em "Text", arraste o elemento "AI Agent > output" (que é a resposta gerada pelo bot) da seção de dados pinados na esquerda para este campo.

Salve o workflow e ative-o.

3. Teste Final
Agora, você pode testar o fluxo completo enviando mensagens para o número do WhatsApp configurado no Waha. O n8n deverá processar a mensagem, gerar uma resposta com o AI Agent e enviá-la de volta via Waha.
