#!/bin/bash
# Este script deve ser executado como root.
# --- Configurações Iniciais ---
CERT_DIR="./n8n_ssl_local" # Diretório onde os certificados serão salvos
CERT_NAME="n8n_local"      # Nome base para os arquivos de certificado e chave
# --- Coletar Informações do Usuário ---
echo "--- Geração de Certificado SSL Autoassinado para n8n Local ---"
echo "Este certificado será usado para acesso HTTPS seguro dentro da sua rede local."
echo ""
echo ""
echo "--- Gerador de certificao auto assinado  ---"
echo "m3ss14s 2025 | homelab"
echo "Este script irá gerar arquivos de certificado para usar no n8n "
echo "Certifique-se de que você tem privilégios de sudo."
echo ""
echo "
  ____          _   _  __ _               _         ____ ____  _     
 / ___|___ _ __| |_(_)/ _(_) ___ __ _  __| | ___   / ___/ ___|| |    
| |   / _ \ '__| __| | |_| |/ __/ _` |/ _` |/ _ \  \___ \___ \| |    
| |__|  __/ |  | |_| |  _| | (_| (_| | (_| | (_) |  ___) |__) | |___ 
 \____\___|_|   \__|_|_| |_|\___\__,_|\__,_|\___/  |____/____/|_____|
                       

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
"

read -p "Digite o IP ou Nome de Host que você usará para acessar o n8n (ex: 192.168.2.47 ou host.docker.internal): " N8N_HOST_OR_IP
if [ -z "$N8N_HOST_OR_IP" ]; then
    echo "Erro: O IP ou Nome de Host não pode ser vazio. Saindo."
    exit 1
fi

read -p "Digite o número de dias de validade para o certificado (padrão: 365): " VALIDITY_DAYS
VALIDITY_DAYS=${VALIDITY_DAYS:-365}

echo ""
echo "Agora, você será solicitado a inserir informações para o certificado SSL."
echo "Para 'Common Name (e.g. server FQDN or YOUR name)', use: ${N8N_HOST_OR_IP}"
echo ""

# --- Criar o Diretório para os Certificados ---
mkdir -p "$CERT_DIR"
if [ $? -ne 0 ]; then
    echo "Erro: Não foi possível criar o diretório $CERT_DIR. Verifique as permissões."
    exit 1
fi
echo "Diretório de certificados criado em: $CERT_DIR"

# --- Gerar a Chave Privada ---
echo "Gerando a chave privada (${CERT_NAME}.key)..."
openssl genrsa -out "${CERT_DIR}/${CERT_NAME}.key" 2048
if [ $? -ne 0 ]; then
    echo "Erro: Falha ao gerar a chave privada."
    exit 1
fi

# --- Gerar o Certificado Autoassinado (CSR e assinar) ---
echo "Gerando o certificado autoassinado (${CERT_NAME}.crt)..."
# Usamos -subj para preencher automaticamente alguns campos e evitar prompts excessivos.
# O CN (Common Name) é o mais importante e será o N8N_HOST_OR_IP fornecido.
openssl req -new -x509 -days "$VALIDITY_DAYS" -key "${CERT_DIR}/${CERT_NAME}.key" -out "${CERT_DIR}/${CERT_NAME}.crt" \
-subj "/C=BR/ST=Sao Paulo/L=Ourinhos/O=Local N8N/OU=IT/CN=${N8N_HOST_OR_IP}"
if [ $? -ne 0 ]; then
    echo "Erro: Falha ao gerar o certificado autoassinado."
    exit 1
fi

echo ""
echo "--- Geração de Certificados Concluída! ---"
echo "Seu certificado autoassinado e chave privada foram gerados em: ${CERT_DIR}/"
echo "  - Chave Privada: ${CERT_DIR}/${CERT_NAME}.key"
echo "  - Certificado:   ${CERT_DIR}/${CERT_NAME}.crt"
echo ""
echo "Próximo passo: Configurar o n8n para usar esses certificados."
echo ""
echo "
███╗   ███╗██████╗ ███████╗███████╗ ██╗██╗  ██╗███████╗
████╗ ████║╚════██╗██╔════╝██╔════╝███║██║  ██║██╔════╝
██╔████╔██║ █████╔╝███████╗███████╗╚██║███████║███████╗
██║╚██╔╝██║ ╚═══██╗╚════██║╚════██║ ██║╚════██║╚════██║
██║ ╚═╝ ██║██████╔╝███████║███████║ ██║     ██║███████║
╚═╝     ╚═╝╚═════╝ ╚══════╝╚══════╝ ╚═╝     ╚═╝╚══════╝

"
