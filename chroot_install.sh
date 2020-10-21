#!/bin/bash

TRUE=0
FALSE=1

# return codes
SUCCESS=1337
FAILURE=31337

# Colors
WHITE="`tput setaf 7`"
WHITEB="`tput bold ; tput setaf 7`"
GREEN="`tput setaf 2`"
GREENB="`tput bold ; tput setaf 2`"
RED="`tput setaf 1`"
REDB="`tput bold; tput setaf 1`"
YELLOW="`tput setaf 3`"
YELLOWB="`tput bold ; tput setaf 3`"
BLINK="`tput blink`"

NORMAL_USER=""

wprintf() {
  fmt="${1}"
  shift
  printf "%s${fmt}%s" "${WHITE}" "${@}" "${NC}"
  return $SUCCESS
}

warn() {
  printf "%s[!] WARNING: %s%s\n" "${YELLOW}" "${@}" "${NC}"
  return $SUCCESS
}

err() {
  printf "%s[-] ERROR: %s%s\n" "${RED}" "${@}" "${NC}"
  exit $FAILURE
}

banner() {
  columns="$(tput cols)"
  str="*********************** Arch Linux iust the way I like it ;) ***************************"

  printf "${REDB}%*s${NC}\n" "${COLUMNS:-$(tput cols)}" | tr ' ' '-'

  echo "${str}" |
  while IFS= read -r line
  do
    printf "%s%*s\n%s" "${YELLOWB}" $(( (${#line} + columns) / 2)) \
      "$line" "${NC}"
  done
  printf "${REDB}%*s${NC}\n\n\n" "${COLUMNS:-$(tput cols)}" | tr ' ' '-'
  return $SUCCESS
}

sleep_clear(){
  sleep $1
  clear

  return $SUCCESS
}

title() {
  banner
  printf "${GREEN}>> %s${NC}\n\n\n" "${@}" "${WHITE}" && printf "\e[0m" # Reset term color like this for now

  return $SUCCESS
}

check_env() {
  if [ -f "/var/lib/pacman/db.lck" ]
  then
    err "pacman locked - Please remove /var/lib/pacman/db.lck"
  fi
}

check_uid() {
  if [ `id -u` -ne 0 ]
  then
    err "You must be root to run the Arch Linux installer!"
  fi

  return $SUCCESS
}

enable_pacman_multilib_add_archlinuxfr() {
  title "Update pacman.conf"

  if [ "`uname -m`" = "x86_64" ]
  then
    wprintf "[+] Enabling multilib support"
    printf "\n\n"
    if grep -q "#\[multilib\]" /etc/pacman.conf
    then
      sed -i '/\[multilib\]/{ s/^#//; n; s/^#//; }' /etc/pacman.conf
    elif ! grep -q "\[multilib\]" /etc/pacman.conf
    then
      printf "[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" \
        >> /etc/pacman.conf
    fi
  fi

  return $SUCCESS
}

enable_pacman_color() {
  title "Update pacman.conf"

  wprintf "[+] Enabling color mode"
  printf "\n\n"

  sed -i 's/^#Color/Color/' /etc/pacman.conf

  return $SUCCESS
}

update_pkg_database() {
  title "Update pacman database"

  wprintf "[+] Updating pacman database"
  printf "\n\n"

  pacman -Syy --noconfirm

  return $SUCCESS
}

update_pacman() {
  title "Update Pacman"
  enable_pacman_multilib_add_archlinuxfr
  sleep_clear 1

  enable_pacman_color
  sleep_clear 1

  update_pkg_database
  sleep_clear 1

  return $SUCCESS
}

locale_zoneinfo_hostname () {
  title "Do Zone Info Stuff"
  # Comment out locale UTF-8
  sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
  locale-gen
  echo "LANG=en_US.UTF-8" > /etc/locale.conf
  export LANG=en_US.UTF-8

  # Change Time zone
  ln -sfv /usr/share/zoneinfo/US/Central /etc/localtime
  # Update hardware clock
  hwclock --systohc --utc

  sleep_clear 1
  title "Adding HOST_NAME"
  echo "great_grand" > /etc/hostname

  return $SUCCESS
}

install_blackarch () {
  title "Installing Blackarch"
  #Installing Blackarch linux Tools
  curl -O https://blackarch.org/strap.sh
  chmod +x strap.sh
  ./strap.sh
  shred -n 30 -uvz strap.sh

  return $SUCCESS
}

user_creation () {
  title "User Creation"

  wprintf "Enter root user password: \n"
  passwd

  wprintf "\nEnter Normal User username: "
  read NORMAL_USER
  useradd -m -g users -G wheel,games,power,optical,storage,scanner,lp,audio,video -s /bin/bash $NORMAL_USER
  passwd $NORMAL_USER

  EDITOR=vim visudo

  return $SUCCESS
}

install_bootloader () {
  title "Installing Bootloader"
  pacman -S gptfdisk syslinux --noconfirm
  pacman -S mkinitcpio linux linux-firmware --noconfirm
  syslinux-install_update -iam

  # Update syslinux config
  device_file=$(lsblk -r -o name,fstype | grep crypto_LUKS | awk '{printf $1}')
  echo "
  DEFAULT arch
  Label arch
    LINUX ../vmlinuz-linux
    APPEND cryptdevice=/dev/${device_file}:r00t root=/dev/mapper/r00t rw ipv6.disable=1
    INITRD ../initramfs-linux.img
  " > /boot/syslinux/syslinux.cfg

  sed -i 's/block filesystems/block encrypt filesystems/g' /etc/mkinitcpio.conf
  pacman -S f2fs-tools btrfs-progs --noconfirm

  return $SUCCESS
}

install_graphics_audio_and_others () {
  title "Installing graphics/audio and other software that I use regularly"

  pacman -S wayland wayland-protocols libinput xorg-server-xwayland --noconfirm
  pacman -S evince --noconfirm
  pacman -S alsa alsa-utils pulseaudio pulseaudio-alsa --noconfirm
  pacman -S bluez bluez-utils pulseaudio-bluetooth --noconfirm
  pacman -S brightnessctl --noconfirm
  pacman -S playerctl --noconfirm
  pacman -S nautilus --noconfirm
  pacman -S mlocate --noconfirm
  pacman -S termite --noconfirm
  # To take screenshot in a wayland compositor
  pacman -S grim --noconfirm
  pacman -S slurp --noconfirm

  # Install keepassx dependecies
  pacman -S qt5-base qt5-tools --noconfirm

  pacman -S bash-completion --noconfirm

  return $SUCCESS
}

install_networking () {
  title "Network Package Installation"

  pacman -S iwd net-tools --noconfirm
  pacman -S tor --noconfirm
  pacman -S proxychains-ng --noconfirm
  pacman -S openssh openvpn --noconfirm

  # FireWall
  pacman -S ufw --noconfirm

  systemctl enable iwd.service
  systemctl enable systemd-resolved.service

  return $SUCCESS
}

install_virtul_soft () {
  title "Installing VM Software"
  pacman -S qemu qemu-arch-extra --noconfirm
  return $SUCCESS
}

install_de () {
  title "Installing Desktop Environment"
  pacman -S sway i3-gaps --noconfirm
  return $SUCCESS
}

install_power () {
  title "Installing power packages"
  pacman -S tlp --noconfirm
  pacman -S acpi --noconfirm
  systemctl enable tlp.service
  return $SUCCESS
}

install_yay () {
  title "Installing yay"

  git clone https://aur.archlinux.org/yay.git
  cd yay/
  makepkg -si
  cd ..

  return $SUCCESS
}

install_firefox () {
  title "Installing Firefox"
  pacman -S firefox --noconfirm
  return $SUCCESS
}

copy_configs () {
  title "Copying Configs"

  cp -rv .config /home/$NORMAL_USER
  cp -v .bashrc /home/$NORMAL_USER
  cp -v iwd_main.conf /etc/iwd/main.conf

  mkdir -v /home/$NORMAL_USER/storage
  mkdir -v /home/$NORMAL_USER/Pictures
  cp -v pics/* /home/$NORMAL_USER/Pictures

  chown -Rv $NORMAL_USER:users /home/$NORMAL_USER/.config
  chown -Rv $NORMAL_USER:users /home/$NORMAL_USER/Pictures
  chown -v $NORMAL_USER:users /home/$NORMAL_USER/.bashrc
  chown -v $NORMAL_USER:users /home/$NORMAL_USER/.bash_profile

  return $SUCCESS
}

update_configs() {
  title "Updating Configs"

  # Global Environment Variables
  echo "
  export SDL_VIDEODRIVER=wayland
  export MOZ_ENABLE_WAYLAND=1
  export XDG_SESSION_TYPE=wayland
  export QT_QPA_PLATFORM=xcb
  " >> /etc/bash.bashrc

  # Add vim config
  echo "
  syntax enable
  colorscheme default
  set tabstop=2
  set softtabstop=2
  set number
  filetype indent on
  set wildmenu
  set lazyredraw
  set showmatch
  set incsearch
  set hlsearch
  " >> /etc/vimrc

  return $SUCCESS
}

main () {
  update_pacman
  sleep_clear 2

  locale_zoneinfo_hostname
  sleep_clear 2

  install_blackarch
  sleep_clear 2

  user_creation
  sleep_clear 2

  install_bootloader
  sleep_clear 2

  install_graphics_audio_and_others
  sleep_clear 2

  install_firefox
  sleep_clear 2

  install_networking
  sleep_clear 2

  install_virtul_soft
  sleep_clear 2

  install_de
  sleep_clear 2

  install_power
  sleep_clear 2

  # install_yay
  # sleep_clear 2

  copy_configs
  sleep_clear 2

  update_configs
  sleep_clear 2

  # This is for mlocate
  updatedb

  title "Installation Complete"

  return $SUCCESS
}

main "${@}"
