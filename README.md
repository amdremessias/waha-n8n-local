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
