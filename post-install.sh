#!/bin/bash

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
    sudo pacman -S --noconfirm --needed base-devel git wget xclip nodejs npm
    
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
    
    # Atualizando yay
    log "Atualizando e gerando database do YAY"
    yay -Syu --noconfirm
    log "Instalando pacotes..."
    yay -S --noconfirm spotify spicetify-cli lazygit neovim
    log "Pacotes instalados."
    
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
    sleep && reboot
fi

# gnome extension manager app
# extensions.gnome.org/extension/3193/blur-my-shell/
# extensions.gnome.org/extension/4158/gnome-40-ui-improvements/
# extensions.gnome.org/extension/4548/tactile/
# extensions.gnome.org/extension/7065/tiling-shell/
# extensions.gnome.org/extension/5489/search-light/
