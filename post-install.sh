#!/bin/bash

set -e

EXT_IDS=(3193 4158 4548 7065 5489)
EXT_BASE_URL="https://extensions.gnome.org"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
THME_DIR="$HOME'/.tmp/themes"

# Redirecionar saída para log de debug
LOG_FILE="/tmp/post-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Verifica se o post-install ainda está pendente
if [ -f "$HOME/.post-install-pending" ]; then
  log "Bem-vindo ao seu novo Arch Linux, $USER!"

  # Exemplo: instalar pacotes com pacman
  log "Instalando pacotes necessarios com pacman..."
  sudo pacman -Syu --noconfirm
  sudo pacman -S --noconfirm --needed base-devel git wget xclip gnome-tweaks gnome-shell-extensions gnome-browser-connector unzip curl ntfsprogs dosfstools ghostty tmux tmuxp obsidian stow zsh timeshift eza zsh nodejs pnpm neovim 

  # Atualizar a lista de pacotes Flatpak
  log "Atualizando Flatpak..."
  flatpak update --appstream -y

  # Instalar aplicativos Flatpak
  log "Instalando aplicativos Flatpak..."
  flatpak install -y app.zen_browser.zen com.mattjakeman.ExtensionManager

  # Confirmar instalação
  log "Aplicativos Flatpak instalados com sucesso!"

  # Instalar YAY (AUR helper)
  log "Instalando o YAY (AUR helper)..."
  # Baixar e instalar o YAY
  git clone https://aur.archlinux.org/yay.git .yay
  cd .yay && makepkg -si --noconfirm && cd .. && rm -rf .yay
  log "YAY instalado com sucesso!"

  # atualizando yay
  log "atualizando e gerando database do yay"
  yay -syu --noconfirm
  log "instalando pacotes..."
  yay -s --noconfirm spotify lazygit 
  log "pacotes instalados."

  # oh-my-zsh
  log "Instalando OH-MY-ZSH"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  log "OH-MY-ZSH instalado."
  log "Baixando zsh-autosuggestions & zsh-syntax-highlighting "
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  log "zsh-autosuggestions & zsh-syntax-highlighting instalados"

  log "Instalando powerlevel10k"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
  log "powerlevel10k instalado"

  echo ""
  log "[i] Instalando extensões do GNOME 🧠"

  # Detecta versão do GNOME
  VERSION=$(gnome-shell --version | grep -oE '[0-9]+\.[0-9]+' | head -n1)

  for EXT_ID in "${EXT_IDS[@]}"; do
    log "[>] Instalando extensão ID: $EXT_ID..."

    # Cria pasta temporária
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    # Busca o link de download
    DL_URL=$(curl -s "$EXT_BASE_URL/extension-info/?pk=$EXT_ID&shell_version=$VERSION" \
      | grep -oP '(?<="download_url": ")[^"]*')

    UUID=$(curl -s "$EXT_BASE_URL/extension-info/?pk=$EXT_ID&shell_version=$VERSION" \
      | grep -oP '(?<="uuid": ")[^"]*')

    if [[ -z "$DL_URL" || -z "$UUID" ]]; then
      log "[!] Extensão $EXT_ID não é compatível com GNOME $VERSION ou não encontrada."
      continue
    fi

    curl -LO "$EXT_BASE_URL/$DL_URL"

    # Instala
    DEST="$EXT_DIR/$UUID"
    mkdir -p "$DEST"
    unzip -q *.zip -d "$DEST"

    gnome-extensions enable "$UUID" || log "[!] Não foi possível ativar $UUID, ativa manual se quiser."

    log "[✓] $UUID instalado com sucesso!"
    rm -rf "$TMP_DIR"
  done

  log "[✔] Tudo finalizado."
  
  echo ""
  log "Instalando WhiteSur-gtk-theme"
  mkdir -p $THME_DIR
  git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1 $THME_DIR/WhiteSur-gtk-theme
  cd $THME_DIR/WhiteSur-gtk-theme && ./install.sh -a normal -m -N stable -l --round -t purple && sudo ./tweaks -g -b default 
  cd $HOME && rm -rf $THME_DIR
  log "WhiteSur-gtk-theme installado!"

  echo ""
  log "Digite o nome para configurar o GIT"
  read -r USERNAME
  if [ -z "$USERNAME" ]; then
    log "Nome de usuário não pode ser vazio! Tente novamente."
    exit 1
  fi
  log "Digite o email para configurar o GIT"
  read -r EMAIL
  if [ -z "$EMAIL" ]; then
    log "O email não pode ser vazio! Tente novamente."
    exit 1
  fi

  git config --global user.name $USERNAME
  git config --global user.email $EMAIL
  ssh-keygen -t ed25519 -C $EMAIL

  log "GIT e chave SSH configurados"

  # Configurar Ghosty como terminal padrão
  # su - "$USER" -c "gsettings set org.gnome.desktop.default-applications.terminal exec 'ghostty'"
  # su - "$USER" -c "gsettings set org.gnome.desktop.default-applications.terminal exec-arg ''"

  # Configurar atalho de teclado Super+T para abrir o Alacritty
  # su - "$USER" -c "gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \"['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']\""
  # su - "$USER" -c "gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Open Terminal'"
  # su - "$USER" -c "gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'ghosttu'"
  # su - "$USER" -c "gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>g'"
  
  log "Limpando pós instalação..."

  # Remove a flag de pós-instalação
  rm "$HOME/.post-install-pending"

  # Remove o arquivo .desktop do autostart
  rm "$HOME/.config/autostart/post-install.desktop"

  # Remove o próprio script de pós-instalação
  rm "$0"

  log "Pós-instalação concluída!"
  log "Log completo disponível em $LOG_FILE"
  echo ""
  log "Reiniciando em 5s..."
  # Reiniciando
  sleep 5 
  reboot
fi

# gnome extension manager app
# extensions.gnome.org/extension/3193/blur-my-shell/
# extensions.gnome.org/extension/4158/gnome-40-ui-improvements/
# extensions.gnome.org/extension/4548/tactile/
# extensions.gnome.org/extension/7065/tiling-shell/
# extensions.gnome.org/extension/5489/search-light/
#
# WhiteSur-gtk-theme
# https://github.com/vinceliuice/WhiteSur-gtk-theme
# command: ./install -a normal -m -N stable -l --round -t purple
