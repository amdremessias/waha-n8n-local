#!/bin/bash



# Este script deve ser executado como root.



# Função para verificar se o Docker e o Docker Compose estão instalados
check_docker_dependencies() {
    if ! command -v docker &> /dev/null; then
        echo "Docker não encontrado. Instalando Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
        echo "Docker instalado com sucesso."
    else
        echo "Docker já está instalado."
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose não encontrado. Instalando Docker Compose..."
        sudo apt-get update
        sudo apt-get install -y docker-compose
        echo "Docker Compose instalado com sucesso."
    else
        echo "Docker Compose já está instalado."
    fi
}

# Solicitar variáveis do usuário
echo ""
echo ""
echo "--- Instalação do ambiente para ChatBot com n8n+waha  ---"
echo "m3ss14s 2025 | homelab"
echo "Este script irá instalar n8n+waha+redis no seu sistema."
echo "Certifique-se de que você tem privilégios de sudo."
echo ""
echo "
 ______________
||            ||
||            ||
||            ||
||            ||
||____________||
|______________|
 \\##############\\
  \\##############\\
   \      ____    \   
    \_____\___\____\... Iniciando Automação | @m3ss14s-2025

        ___                           _           
 _ __  ( _ ) _ __    _ __      ____ _| |__   __ _ 
| '_ \ / _ \| '_ \ _| |\ \ /\ / / _` | '_ \ / _` |
| | | | (_) | | | |_   _\ V  V / (_| | | | | (_| |
|_| |_|\___/|_| |_| |_|  \_/\_/ \__,_|_| |_|\__,_|
                                                 
"

read -p "Digite a senha do Redis (padrão: default): " REDIS_PASSWORD
REDIS_PASSWORD=${REDIS_PASSWORD:-default}

read -p "Digite o usuário do PostgreSQL (padrão: default): " POSTGRES_USER
POSTGRES_USER=${POSTGRES_USER:-default}

read -p "Digite a senha do PostgreSQL (padrão: default): " POSTGRES_PASSWORD
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-default}

read -p "Digite o nome do banco de dados PostgreSQL (padrão: default): " POSTGRES_DB
POSTGRES_DB=${POSTGRES_DB:-default}

read -p "Digite a URL do Webhook para WAHA (padrão: http://host.docker.internal:5678/webhook/webhook): " WHATSAPP_HOOK_URL
WHATSAPP_HOOK_URL=${WHATSAPP_HOOK_URL:-http://host.docker.internal:5678/webhook/webhook}

read -p "Digite o host para N8N (padrão: host.docker.internal): " N8N_HOST
N8N_HOST=${N8N_HOST:-host.docker.internal}

# Criar o arquivo docker-compose.yml com as variáveis personalizadas
cat << EOF > docker-compose.yml
version: '3.8'

services:
  redis:
    image: redis:latest
    platform: linux/amd64
    command: redis-server --requirepass ${REDIS_PASSWORD}
    environment:
      REDIS_USER: default
      REDIS_PASSWORD: ${REDIS_PASSWORD}
    ports:
      - "6379:6379"

  postgres:
    image: postgres:latest
    platform: linux/amd64
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  waha:
    image: devlikeapro/waha:latest
    platform: linux/amd64
    environment:
      WHATSAPP_HOOK_URL: ${WHATSAPP_HOOK_URL}
      WHATSAPP_DEFAULT_ENGINE: GOWS
      WHATSAPP_HOOK_EVENTS: message
    volumes:
      - waha_sessions:/app/.sessions
      - waha_media:/app/.media
    ports:
      - "3000:3000"

  n8n:
    image: n8nio/n8n:latest
    platform: linux/amd64
    environment:
      WEBHOOK_URL: http://${N8N_HOST}:5678
      N8N_HOST: ${N8N_HOST}
      GENERIC_TIMEZONE: America/Sao_Paulo
      N8N_LOG_LEVEL: debug
      N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE: "true"
    volumes:
      - n8n_data:/home/node/.n8n
    ports:
      - "5678:5678"

volumes:
  pgdata:
  waha_sessions:
  waha_media:
  n8n_data:
EOF

echo "Arquivo docker-compose.yml gerado com sucesso com as configurações personalizadas!"

# Verificar e instalar dependências do Docker
check_docker_dependencies

# Iniciar os serviços Docker Compose
echo "Iniciando os serviços Docker Compose..."
docker-compose up -d

echo "Instalação concluída! Os serviços Docker estão rodando em segundo plano."
echo "Você pode verificar o status dos contêineres com 'docker-compose ps'."
echo "CONFIGURE SSL/TLS PARA O N8N com o arquivo gerador-certificado.sh e reconfigure o compose.ym "
echo ""

echo "
███╗   ███╗██████╗ ███████╗███████╗ ██╗██╗  ██╗███████╗
████╗ ████║╚════██╗██╔════╝██╔════╝███║██║  ██║██╔════╝
██╔████╔██║ █████╔╝███████╗███████╗╚██║███████║███████╗
██║╚██╔╝██║ ╚═══██╗╚════██║╚════██║ ██║╚════██║╚════██║
██║ ╚═╝ ██║██████╔╝███████║███████║ ██║     ██║███████║
╚═╝     ╚═╝╚═════╝ ╚══════╝╚══════╝ ╚═╝     ╚═╝╚══════╝
"