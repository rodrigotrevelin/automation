#!/bin/bash

# Script de instalação automatizada do Arch Linux com EFISTUB
# Execute como root no ambiente live

# Redirecionar saída para log de debug
LOG_FILE="/tmp/install.log"
exec > >(tee -a "$LOG_FILE") 2>&1
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Início do script install-arch"

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  log "Este script deve ser executado como root!"
  exit 1
fi

# Verifica se o arquivo post-install.sh existe no mesmo diretório
POST_INSTALL_SRC="$(dirname "$0")/post-install.sh"
if [ ! -f "$POST_INSTALL_SRC" ]; then
  log "Erro: O arquivo post-install.sh não foi encontrado no mesmo diretório deste script!"
  exit 1
fi

# Carregar variáveis de configuração de config.sh
CONFIG_FILE="$(dirname "$0")/config.sh"
if [ -f "$CONFIG_FILE" ]; then
  log "Carregando variáveis de $CONFIG_FILE..."
  source "$CONFIG_FILE"
else
  log "Erro: Arquivo $CONFIG_FILE não encontrado!"
  exit 1
fi

# Verificar se as variáveis essenciais estão configuradas corretamente
if [ -z "$DISK_NVME" ] || [ -z "$DISK_HD" ] || [ -z "$TIMEZONE" ] || [ -z "$HOSTNAME" ]; then
  log "Erro: Uma ou mais variáveis essenciais não estão configuradas corretamente em config.sh!"
  exit 1
fi

# Mensagem informativa para a senha do root
clear
log "======================================================"
log "██████╗  ██████╗  ██████╗ ████████╗"
log "██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝"
log "██████╔╝██║   ██║██║   ██║   ██║   "
log "██╔══██╗██║   ██║██║   ██║   ██║   "
log "██║  ██║╚██████╔╝╚██████╔╝   ██║   "
log "╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   "
log "======================================================"
log "Agora, será solicitada a senha do usuário root."
echo ""
log "Pressione Enter para continuar..."
read -r

# Solicitar e confirmar a senha do root
while true; do
  log "Digite a senha para o usuário root:"
  read -s ROOT_PASSWORD
  if [ -z "$ROOT_PASSWORD" ]; then
    log "A senha do root não pode ser vazia! Tente novamente."
    continue
  fi
  log "Confirme a senha do root:"
  read -s ROOT_PASSWORD_CONFIRM
  if [ "$ROOT_PASSWORD" = "$ROOT_PASSWORD_CONFIRM" ]; then
    break
  else
    log "As senhas não coincidem! Tente novamente."
  fi
done

# Mensagem informativa para o nome do usuário
clear
log "======================================================"
log "██╗   ██╗███████╗██╗   ██╗ █████╗ ██████╗ ██╗ ██████╗"
log "██║   ██║██╔════╝██║   ██║██╔══██╗██╔══██╗██║██╔═══██╗"
log "██║   ██║███████╗██║   ██║███████║██████╔╝██║██║   ██║"
log "██║   ██║╚════██║██║   ██║██╔══██║██╔══██╗██║██║   ██║"
log "╚██████╔╝███████║╚██████╔╝██║  ██║██║  ██║██║╚██████╔╝"
log " ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ "
log "======================================================"
log "Vamos criar o seu usuário."
echo ""
log "Pressione Enter para continuar..."
read -r

# Solicitar o nome do usuário
log "Digite o nome do usuário a ser criado:"
read -r USERNAME
if [ -z "$USERNAME" ]; then
  log "Nome de usuário não pode ser vazio! Tente novamente."
  exit 1
fi

# Solicitar e confirmar a senha do usuário
while true; do
  log "Digite a senha para o usuário $USERNAME:"
  read -s USER_PASSWORD
  if [ -z "$USER_PASSWORD" ]; then
    log "A senha do usuário não pode ser vazia! Tente novamente."
    continue
  fi
  log "Confirme a senha do usuário $USERNAME:"
  read -s USER_PASSWORD_CONFIRM
  if [ "$USER_PASSWORD" = "$USER_PASSWORD_CONFIRM" ]; then
    break
  else
    log "As senhas não coincidem! Tente novamente."
  fi
done

# Perguntar se deseja formatar o HD
# https://patorjk.com/software/taag/#p=display&f=ANSI%20Shadow&t=FORMAT
clear
log "======================================================"
log "⚠️  ATENÇÃO: LEIA COM ATENCAO !!! ⚠️"
log "======================================================"
log "███████╗ ██████╗ ██████╗ ███╗   ███╗ █████╗ ████████╗"
log "██╔════╝██╔═══██╗██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝"
log "█████╗  ██║   ██║██████╔╝██╔████╔██║███████║   ██║   "
log "██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║██╔══██║   ██║   "
log "██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║██║  ██║   ██║   "
log "╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   "
log "======================================================"
log "Voce pode apagar o $DISK_HD ou somente adicionar as "
log "particoes ja existentes caso o $DISK_HD nao tenha "
log "sido formatado anteriormente ou tenha sido substituido"
log "======================================================"
log "💀 TODAS AS PARTIÇÕES SERÃO APAGADAS IRREVERSIVELMENTE 💀"
log "------------------------------------------------------"
log "Deseja formatar completamente o disco $DISK_HD? (y/N)"
read -r format_hd_response

if [[ "$format_hd_response" == "y" || "$format_hd_response" == "Y" ]]; then
  log "Particionando o disco $DISK_HD..."
  parted -s "$DISK_HD" mklabel gpt
  parted -s "$DISK_HD" mkpart primary ext4 1MiB 128GiB     # /workspace - 128GB
  parted -s "$DISK_HD" mkpart primary ext4 128GiB 564GiB   # /data - ~436GB
  parted -s "$DISK_HD" mkpart primary ext4 564GiB 100%     # /bkp - ~436GB

  log "Formatando o disco $DISK_HD..."
  mkfs.ext4 "${DISK_HD}1"
  mkfs.ext4 "${DISK_HD}2"
  mkfs.ext4 "${DISK_HD}3"

elif [[ "$format_hd_response" == "n" || "$format_hd_response" == "N" || -z "$format_hd_response" ]]; then
  log "Deseja apenas montar as partições existentes do HD? (y/N)"
  read -r mount_hd_response

  if [[ "$mount_hd_response" != "y" && "$mount_hd_response" != "Y" ]]; then
    log "Ok, as partições do HD não serão montadas."
  else
    log "Montando as partições do HD existentes..."

    mkdir -p /mnt/workspace /mnt/data /mnt/bkp

    # Tentar montar, e validar se deu bom
    mount "${DISK_HD}1" /mnt/workspace || { log "Erro ao montar ${DISK_HD}1 em /mnt/workspace"; exit 1; }
    mount "${DISK_HD}2" /mnt/data || { log "Erro ao montar ${DISK_HD}2 em /mnt/data"; exit 1; }
    mount "${DISK_HD}3" /mnt/bkp || { log "Erro ao montar ${DISK_HD}3 em /mnt/bkp"; exit 1; }

    log "Partições do HD montadas com sucesso."
  fi
else
  log "Resposta inválida. Encerrando."
  exit 1
fi


# Confirmar a instalação
clear
log "======================================================"
log "⚠️  ATENÇÃO: LEIA COM ATENCAO !!! ⚠️"
log "======================================================"
log "██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     "
log "██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     "
log "██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     "
log "██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     "
log "██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗"
log "╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝"
log "======================================================"
log "Este script irá apagar o disco $DISK_NVME e instalar o Arch Linux em $DISK_NVME."
log "Usuário: $USERNAME | Senhas: [ocultas] | Deseja continuar? (y/N)"
read -r resposta
if [[ "$resposta" != "y" && "$resposta" != "Y" ]]; then
  log "Instalação cancelada."
  exit 1
fi

clear
log "======================================================"
log "██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     "
log "██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     "
log "██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     "
log "██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     "
log "██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗"
log "╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝"
log "======================================================"
# Atualizar o relógio do sistema
timedatectl set-ntp true

# Verificar existência dos discos antes de partir para o particionamento
if [ ! -b "$DISK_NVME" ]; then
  log "Erro: O disco $DISK_NVME não foi encontrado!"
  exit 1
fi

# Particionamento do disco NVMe
log "Particionando o disco $DISK_NVME..."
parted -s "$DISK_NVME" mklabel gpt
parted -s "$DISK_NVME" mkpart primary fat32 1MiB 2GiB     # /boot (EFI) - 2GB
parted -s "$DISK_NVME" set 1 esp on
parted -s "$DISK_NVME" mkpart primary linux-swap 2GiB 18GiB  # SWAP - 16GB
parted -s "$DISK_NVME" mkpart primary ext4 18GiB 98GiB     # / - 80GB
parted -s "$DISK_NVME" mkpart primary ext4 98GiB 100%      # /home 

# Formatar as partições do NVMe
log "Formatando o disco $DISK_NVME..."
mkfs.fat -F32 "${DISK_NVME}p1"  # /boot (EFI)
mkswap "${DISK_NVME}p2"         # SWAP
mkfs.ext4 "${DISK_NVME}p3"      # /
mkfs.ext4 "${DISK_NVME}p4"      # /home

# Ativar swap
swapon "${DISK_NVME}p2"

# Montar as partições do NVMe
log "Montando as partições do disco $DISK_NVME..."
mount "${DISK_NVME}p3" /mnt
mkdir /mnt/boot
mkdir /mnt/home
mount "${DISK_NVME}p1" /mnt/boot
mount "${DISK_NVME}p4" /mnt/home

# Instalar o sistema base
clear
log "Instalando pacotes base..."
pacstrap /mnt base linux linux-firmware || { log "Erro ao instalar pacotes base!"; exit 1; }

# Gerar o fstab
log "Gerando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Copiar o post-install.sh para o sistema
#log "Copiando o script post-install.sh para /mnt/home/$USERNAME..."
#cp "$POST_INSTALL_SRC" /mnt/home/$USERNAME/post-install.sh

# Configurar o sistema (chroot)
log "Configurando o sistema com chroot..."
arch-chroot /mnt /bin/bash <<EOF || { log "Erro durante o chroot!"; exit 1; }

# Configurar fuso horário
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Configurar locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Configurar hostname
echo "$HOSTNAME" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

# Definir senha do root
echo "root:$ROOT_PASSWORD" | chpasswd

# Instalar pacotes adicionais
clear
pacman -Syu --noconfirm
pacman -S --noconfirm networkmanager sudo base-devel gnome gdm efibootmgr ttf-dejavu ttf-dejavu-nerd docker

# Configurar EFISTUB
clear
cp /boot/vmlinuz-linux /boot/vmlinuz-linux.efi
cp /boot/initramfs-linux.img /boot/
efibootmgr -c -d "$DISK_NVME" -p 1 -L "Arch Linux" -l "\vmlinuz-linux.efi" -u "root=PARTUUID=$(blkid -s PARTUUID -o value ${DISK_NVME}p2) rw initrd=\initramfs-linux.img"

## Criar usuário e adicionar ao grupo wheel (sudo)
useradd -m -G wheel -s /bin/bash "$USERNAME"
## Adiciona usuario ao docker
#usermod -aG docker "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd

# Configurar a fonte DejaVu como padrão no GNOME para o usuário
#su - "$USERNAME" -c "gsettings set org.gnome.desktop.interface font-name 'DejaVu Sans 11'"
#su - "$USERNAME" -c "gsettings set org.gnome.desktop.interface document-font-name 'DejaVu Sans 11'"
#su - "$USERNAME" -c "gsettings set org.gnome.desktop.interface monospace-font-name 'DejaVu Sans Mono 11'"

# Ajustar permissões e tornar o post-install.sh executável
#cp post-install.sh /mnt/home/$USERNAME/post-install.sh
#chmod +x /home/$USERNAME/post-install.sh
#chown $USERNAME:$USERNAME /mnt/home/$USERNAME/post-install.sh

# Criar o diretório autostart e o arquivo .desktop
#mkdir -p /mnt/home/$USERNAME/.config/autostart
#cat <<EOF > /mnt/home/$USERNAME/.config/autostart/post-install.desktop
#[Desktop Entry]
#Type=Application
#Name=Post Install Script
#Exec=gnome-terminal -- bash -c "/home/$USERNAME/post-install.sh; read -n 1 -s -r -p 'Press any key to close...'"
#Hidden=false
#NoDisplay=false
#X-GNOME-Autostart-enabled=true
#EOF

#chown -R $USERNAME:$USERNAME /mnt/home/$USERNAME/.config

# Criar flag para indicar que o post-install está pendente
#touch /mnt/home/$USERNAME/.post-install-pending
#chown $USERNAME:$USERNAME /mnt/home/$USERNAME/.post-install-pending

# Habilitar serviços
systemctl enable NetworkManager
systemctl enable gdm
systemctl enable bluetooth
systemctl enable docker

# Garantir que o grupo wheel tenha privilégios de sudo
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Criar diretórios permanentes para as partições do HD
#mkdir -p /workspace /data /bkp
#chown $USERNAME:$USERNAME /workspace /data /bkp

exit
EOF

# Verificar status do chroot
clear
if [ $? -ne 0 ]; then
  log "Erro durante a configuracao no chroot!"
  exit 1
fi

# Desmontar e reiniciar
clear
log "======================================================"
log "███████╗██╗███╗   ██╗██╗███████╗██╗  ██╗███████╗██████╗ "
log "██╔════╝██║████╗  ██║██║██╔════╝██║  ██║██╔════╝██╔══██╗"
log "█████╗  ██║██╔██╗ ██║██║███████╗███████║█████╗  ██║  ██║"
log "██╔══╝  ██║██║╚██╗██║██║╚════██║██╔══██║██╔══╝  ██║  ██║"
log "██║     ██║██║ ╚████║██║███████║██║  ██║███████╗██████╔╝"
log "╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═════╝ "
log "======================================================"
log "Desmontando partições e reiniciando..."
umount -R /mnt || { log "Erro ao desmontar as partições!"; exit 1; }
log "Instalação concluída com sucesso! "
echo ""
log "Log completo disponível em $LOG_FILE"

# Recomendar a desconexão do meio de instalação
log "Você pode remover o pen-drive."
log "Reiniciando em 5s..."

# Reiniciar o sistema
sleep 5
reboot

