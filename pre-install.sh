#!/bin/bash
#
# Como Usar:
# 1. Torne o script executável: chmod +x pre-install.sh
# 2. Execute: ./pre-install.sh -r https://github.com/rodrigotrevelin/automation
# 3. Após a execução, os scripts install-arch.sh e post-install.sh estarão no diretório atual.
# 4. Para verificar o log de debug, use: cat /tmp/pre-install.log
#

# Redirecionar saída para log de debug
LOG_FILE="/tmp/pre-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Início do script pre-install"

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  log "Este script deve ser executado como root!"
  exit 1
fi

# Função para verificar e instalar dependências
check_and_install_deps() {
  local missing_deps=()
  for cmd in git wget; do
    if ! command -v "$cmd" &> /dev/null; then
      missing_deps+=("$cmd")
    fi
  done

  if [ ${#missing_deps[@]} -gt 0 ]; then
    log "Erro: Dependências ausentes: ${missing_deps[*]}"
    log "Tentando instalar via pacman..."
    pacman -Sy --noconfirm "${missing_deps[@]}" || {
      log "Erro: Falha ao instalar ${missing_deps[*]} com pacman!"
      exit 1
    }
    log "Dependências instaladas com sucesso. Reexecutando o script..."
    exec "$0" "$@"
  fi
}

# Variáveis
BRANCH="main"
REPO_URL=""

# Processar a opção -r
while getopts "r:" opt; do
  case $opt in
    r) REPO_URL="$OPTARG";;
    ?) echo "Uso: $0 -r URL_DO_REPOSITORIO"
       exit 1;;
  esac
done

# Verificar se REPO_URL foi fornecida
if [ -z "$REPO_URL" ]; then
  log "Erro: A opção -r é obrigatória! Forneça a URL do repositório."
  log "Uso: $0 -r URL_DO_REPOSITORIO"
  exit 1
fi

# Informar a REPO_URL no início
log "URL do repositório a ser usada: $REPO_URL"

# Verificar dependências
check_and_install_deps

# Variáveis
TEMP_DIR="/tmp/arch-install"

# Criar diretório temporário
log "Criando diretório temporário em $TEMP_DIR..."
mkdir -p "$TEMP_DIR" || {
  log "Erro ao criar diretório temporário!"
  exit 1
}

# Tentar clonar com git primeiro
log "Clonando o repositório com git..."
if git clone -b "$BRANCH" "$REPO_URL" "$TEMP_DIR/repo"; then
  log "Repositório clonado com sucesso via git."
else
  log "Falha ao clonar com git. Baixando com wget..."
  wget -q "$REPO_URL/archive/refs/heads/$BRANCH.tar.gz" -O "$TEMP_DIR/repo.tar.gz" || {
    log "Erro ao baixar o repositório com wget!"
    exit 1
  }
  tar -xzf "$TEMP_DIR/repo.tar.gz" -C "$TEMP_DIR" || {
    log "Erro ao extrair os arquivos!"
    exit 1
  }
  mv "$TEMP_DIR/$(basename "$REPO_URL")-$BRANCH" "$TEMP_DIR/repo" || {
    log "Erro ao renomear diretório extraído!"
    exit 1
  }
fi

# Mover os scripts para o diretório atual
log "Movendo scripts para o diretório atual..."
mv "$TEMP_DIR/repo/install-arch.sh" "$TEMP_DIR/repo/post-install.sh" . || {
  log "Erro ao mover os scripts!"
  exit 1
}

# Tornar os scripts executáveis
log "Tornando os scripts executáveis..."
chmod +x install-arch.sh post-install.sh || {
  log "Erro ao ajustar permissões dos scripts!"
  exit 1
}

# Limpar arquivos temporários
log "Limpando arquivos temporários..."
rm -rf "$TEMP_DIR" || {
  log "Aviso: Falha ao remover $TEMP_DIR, remova manualmente."
}

log "Scripts baixados com sucesso! "
log "Execute ./install-arch.sh para iniciar a instalação."
echo " "
log "Log completo disponível em $LOG_FILE"
