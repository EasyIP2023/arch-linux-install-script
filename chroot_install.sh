#!/bin/bash

TRUE=0
FALSE=1

# return codes
SUCCESS=1337
FAILURE=31337

#Colors
WHITE="`tput setaf 7`"
WHITEB="`tput bold ; tput setaf 7`"
GREEN="`tput setaf 2`"
GREENB="`tput bold ; tput setaf 2`"
RED="`tput setaf 1`"
REDB="`tput bold; tput setaf 1`"
YELLOW="`tput setaf 3`"
YELLOWB="`tput bold ; tput setaf 3`"
BLINK="`tput blink`"

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
  return $SUCCESS
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
  return "$SUCCESS"
}

sleep_clear(){
  sleep $1
  clear

  return $SUCCESS
}

title() {
  banner
  printf "${GREEN}>> %s${NC}\n\n\n" "${@}"

  return "${SUCCESS}"
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

zoneinfo_hostname () {
  title "Do Zone Info Stuff"
  # Comment out locale UTF-8
  sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
  locale-gen
  echo LANG=en_US.UTF-8 > /etc/locale.conf
  export LANG=en_US.UTF-8

  #Change Time
  ln -s /usr/share/zoneinfo/US/Central > /etc/localtime
  hwclock --systohc --utc

  sleep_clear 1
  title "Adding HOST_NAME"
  echo "great_grand" > /etc/hostname

  return $SUCCESS
}

install_blackarch () {
  title "Installing Blackarch"
  #Installing Blackarch linux Tools
  wget -O strap.sh http://blackarch.org/strap.sh
  chmod 777 strap.sh
  ./strap.sh
  shred -n 30 -uvz strap.sh

  return $SUCCESS
}

user_creation () {
  title "User Creation"
  passwd

  wprintf "Enter Normal User username: "
  read NORMAL_USER
  useradd -m -g users -G wheel,games,power,optical,storage,scanner,lp,audio,video -s /bin/bash "${NORMAL_USER}"
  passwd "${NORMAL_USER}"

  EDITOR=vim visudo
  pacman -S bash-completion --noconfrim

  return $SUCCESS
}

install_bootloader () {
  title "Installing Bootloader"
  pacman -S gptfdisk syslinux --noconfirm
  syslinux-install_update -iam
  vim /boot/syslinux/syslinux.cfg
  vim /etc/mkinitcpio.conf
  pacman -S f2fs-tools btrfs-progs --noconfirm
  mkinitcpio -p linux

  return $SUCCESS
}

install_graphics_audio_and_others () {
  title "Installing graphics/audio and other software that I use regularly"
  #install stuff like graphics (Intel integrated graphics)
  pacman -S xf86-input-synaptics --noconfirm
  pacman -S wayland wayland-docs wayland-protocols --noconfirm
  pacman -S lib32-mesa-libgl --noconfirm
  pacman -S firefox --noconfirm
  pacman -S libreoffice --noconfirm
  pacman -S bleachbit --noconfirm
  pacman -S yaourt --noconfirm
  pacman -S evince --noconfirm
  pacman -S alsa pulseaudio pulseaudio-alsa --noconfirm
  pacman -S playerctl --noconfirm
  pacman -S nautilus --noconfirm
  pacman -S gnome-screenshot --noconfirm
  pacman -S xcompmgr --noconfirm

  return $SUCCESS
}

install_java () {
  title "Java Install"
  pacman -S jre-openjdk-headless jre-openjdk jdk-openjdk openjdk-doc openjdk-src jre10-openjdk-headless jre10-openjdk jdk10-openjdk openjdk10-doc openjdk10-src java-openjfx java-openjfx-doc java-openjfx-src --noconfirm

  return $SUCCESS
}

install_networking () {
  title "Network Package Installation"
  pacman -S networkmanager networkmanager-openconnect networkmanager-openvpn networkmanager-pptp networkmanager-vpnc wpa_supplicant wireless_tools dialog net-tools --noconfirm
  pacman -S nm-connection-editor --noconfirm
  systemctl enable NetworkManager.service
  pacman -S tor --noconfirm
  pacman -S proxychains-ng --noconfirm
  pacman -S macchanger --noconfirm
  # FireWall
  pacman -S ufw --noconfirm

  return $SUCCESS
}

install_virtul_soft () {
  title "Installing VM Software"
  pacman -S qemu qemu-arch-extra --noconfirm

  return $SUCCESS
}

install_de () {
  title "Installing Desktop Environment"
  # Install desktop environment
  pacman -S sway i3-gaps --noconfirm

  # Add sway to file and comment out exec xterm
  # sed -i 's/exec xterm -geometry 80x66+0+0 -name login/sway/g' /etc/X11/xinit/xinitrc
  cat "Replace ExecStart=... with ExecStart=-/usr/bin/agetty --autologin <username> --noclear %I $TERM"
  cat "Re-look at script for more information"
  sleep 5s
  vim /etc/systemd/system/getty.target.wants/getty@tty1.service

  return $SUCCESS
}

install_powertop () {
  # Installing powertop
  pacman -S powertop --noconfirm

  return $SUCCESS
}

main () {
  update_pacman
  sleep_clear 1

  zoneinfo_hostname
  sleep_clear 1

  install_blackarch
  sleep_clear 1

  user_creation
  sleep_clear 1

  install_bootloader
  sleep_clear 1

  install_graphics_audio_and_others
  sleep_clear 1

  install_java
  sleep_clear 1

  install_networking
  sleep_clear 1

  install_virtul_soft
  sleep_clear 1

  install_de
  sleep_clear 1

  return $SUCCESS
}

main "${@}"

title "Update configs"

cat >> /etc/pacman.conf << "EOF"
[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/$arch
EOF
pacman -Syy

cat >> /etc/bash.bashrc << "EOF"

if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
  XKB_DEFAULT_LAYOUT=us exec sway
fi
EOF

cat > /etc/systemd/system/powertop.service << "EOF"
[Unit]
Description=Powertop tunings

[Service]
Type=oneshot
ExecStart=/usr/bin/powertop --auto-tune

[Install]
WantedBy=multi-user.target
EOF
systemctl enable powertop.service

# Add Macspoof Config
cat > /etc/systemd/system/macspoof@.service << "EOF"
[Unit]
Description=macchanger on %I
Wants=network-pre.target
Before=network-pre.target
BindsTo=sys-subsystem-net-devices-%i.device
After=sys-subsystem-net-devices-%i.device

[Service]
ExecStart=/usr/bin/macchanger -r %I
Type=oneshot

[Install]
WantedBy=multi-user.target
EOF

# Add vim config
cat >> /etc/vimrc << "EOF"
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
EOF

ifconfig
printf "Enter ethernet address(xx:xx:xx:xx:xx:xx): "
read ETHER
printf "Enter wireless address(xx:xx:xx:xx:xx:xx): "
read WLAN
cat > /etc/udev/rules.d/10-network.rules << "EOF"
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="${ETHER}", NAME="eth0"
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="${WLAN}", NAME="wlan0"
EOF

cp -v i3_config /home/vince/.config/i3/config
cp -v .bashrc /home/vince/.bashrc
chown -v vince:users /home/vince/.config/i3/config
chown -v vince:users /home/vince/.bashrc

printf "Installation Complete"
