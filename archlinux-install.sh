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

HOST_NAME=""
HD_BOOT=""
HD_ROOT=""
HD_SDA="/dev/sda"
RUBY_VERSION=""
BOOT_PART=""
ROOT_PART=""

CRYPT_ROOT="root"

CHROOT="/mnt"
NORMAL_USER=""
WLAN=""
ETHER=""

wprintf(){
  fmt="${1}"
  shift
  printf "%s${fmt}%s" "${WHITE}" "${@}" "${NC}"
  return $SUCCESS
}


warn(){
  printf "%s[!] WARNING: %s%s\n" "${YELLOW}" "${@}" "${NC}"
  return $SUCCESS
}

err(){
  printf "%s[-] ERROR: %s%s\n" "${RED}" "${@}" "${NC}"
  exit $FAILURE
  return $SUCCESS
}

banner()
{
  columns="$(tput cols)"
  str="*********************** Arch Linux Installer Script (Script Is designed fot how I install)  ***************************"

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

title()
{
  banner
  printf "${GREEN}>> %s${NC}\n\n\n" "${@}"

  return "${SUCCESS}"
}

check_env()
{
  if [ -f "/var/lib/pacman/db.lck" ]
  then
    err "pacman locked - Please remove /var/lib/pacman/db.lck"
  fi
}

check_uid()
{
  if [ `id -u` -ne 0 ]
  then
    err "You must be root to run the Arch Linux installer!"
  fi

  return $SUCCESS
}

enable_pacman_multilib_add_archlinuxfr(){
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
  echo " [archlinuxfr]
  SigLevel = Never
  Server = http://repo.archlinux.fr/$arch" >> /etc/pacman.conf

  return $SUCCESS
}

enable_pacman_color(){
  title "Update pacman.conf"

  wprintf "[+] Enabling color mode"
  printf "\n\n"

  sed -i 's/^#Color/Color/' /etc/pacman.conf

  return $SUCCESS
}

update_pkg_database()
{
  title "Update pacman database"

  wprintf "[+] Updating pacman database"
  printf "\n\n"

  pacman -Syy --noconfirm

  return $SUCCESS
}

update_pacman(){
  title "Update Pacman"
  enable_pacman_multilib_add_archlinuxfr
  sleep_clear 1

  enable_pacman_color
  sleep_clear 1

  update_pkg_database
  sleep_clear 1

  return $SUCCESS
}

ask_hostname(){
  while [ -z "${HOST_NAME}" ]
  do
    title "Network Setup"
    wprintf "[?] Set your hostname: "
    read HOST_NAME
    clear
  done

  return $SUCCESS
}

print_partitions(){
    i=""

    while true
    do
        title "Hard Drive Setup"
        wprintf "[+] Current Partition table"
        printf "\n
    > /boot     : ${HD_BOOT}
    > /         : ${HD_ROOT}
    \n"
        wprintf "[?] Are the partition table correct [y/n]: "
        read i
        if [ "${i}" = "y" -o "${i}" = "Y" ]
        then
            clear
            break
        elif [ "${i}" = "n" -o "${i}" = "N" ]
        then
            echo
            err "Hard Drive Setup aborted. You Suck"
        else
            clear
            continue
        fi
        clear
    done

    return $SUCCESS
}

install_base_system(){
  title "Installing Base System"
  wprintf "[+] Choose a Server"
  sleep 5
  vim /etc/pacman.d/mirrorlist
  pacstrap -i "${CHROOT}" base base-devel

  return $SUCCESS
}

before_chroot(){
  title "Installing System"
  # FIRST Thing Wipe Drive
  # shred --verbose --random-source=/dev/urandom --iterations=3 /dev/sda
  # Part Drive
  parted -a optimal /dev/sda mklabel gpt mkpart primary 0% 257Mib name 1 boot mkpart primary 257Mib 100% name 2 root

  wprintf "[?] Boot partition (/dev/sdXY): "
  read HD_BOOT
  wprintf "[?] Root partition (/dev/sdXY): "
  read HD_ROOT
  sleep_clear 1

  print_partitions
  sleep_clear 1

  mkfs.btrfs -L boot "${HD_BOOT}"
  cryptsetup --verbose --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat "${HD_ROOT}"
  cryptsetup open --type luks "${HD_ROOT}" "${CRYPT_ROOT}"
  mkfs.f2fs -l "/dev/mapper/${CRYPT_ROOT}"
  mount "/dev/mapper/${CRYPT_ROOT}" "${CHROOT}"
  mkdir "${CHROOT}/boot"
  mount "${HD_BOOT}" "${CHROOT}/boot"

  install_base_system
  sleep_clear 1

  genfstab -U -p "${CHROOT}" >> "${CHROOT}/etc/fstab"

  return $SUCCESS
}

install_yubikey(){
  title "[+] Installing Yubikey For Authentication"
  #Install yubiPam for authentication and yubikey personalization tool
  chroot "${CHROOT}" cd /usr/local/src
  chroot "${CHROOT}" git clone https://github.com/firnsy/yubipam.git
  chroot "${CHROOT}" cd yubipam
  chroot "${CHROOT}" autoreconf -i
  chroot "${CHROOT}" ./configure
  chroot "${CHROOT}" make install
  chroot "${CHROOT}" groupadd yubiauth
  chroot "${CHROOT}" touch /etc/yubikey
  chroot "${CHROOT}" chgrp yubiauth /etc/yubikey /usr/local/sbin/yk_chkpwd
  chroot "${CHROOT}" chmod g+rw /etc/yubikey
  chroot "${CHROOT}" chmod g+s /usr/local/sbin/yk_chkpwd
  chroot "${CHROOT}" pacman -S yubikey-personalization-gui --noconfirm
  chroot "${CHROOT}" cd
  return $SUCCESS
}

add_bash_config(){
  title "[+] Add Bash Configs"

  chroot "${CHROOT}" cat > /etc/systemd/system/macspoof@.service << "EOF"
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

  chroot "${CHROOT}" cat >> /etc/vimrc << "EOF"
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

  sleep_clear 1

  title "[+] Network Interface Name Change"
  chroot "${CHROOT}" ifconfig
  chroot "${CHROOT}" printf "Enter ethernet address(xx:xx:xx:xx:xx:xx): "
  chroot "${CHROOT}" read ETHER
  chroot "${CHROOT}" printf "Enter wireless address(xx:xx:xx:xx:xx:xx): "
  chroot "${CHROOT}" read WLAN
  chroot "${CHROOT}" cat > /etc/udev/rules.d/10-network.rules << "EOF"
  SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="${ETHER}", NAME="eth0"
  SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="${WLAN}", NAME="wlan0"
  EOF

  return $SUCCESS
}

#Used for better consumption of power
install_powertop(){
  title "[+] Installing Powertop"
  chroot "${CHROOT}" pacman -S powertop --noconfirm
  chroot "${CHROOT}" cat > /etc/systemd/system/powertop.service << EOL
  [Unit]
  Description=Powertop tunings

  [Service]
  Type=oneshot
  ExecStart=/usr/bin/powertop --auto-tune

  [Install]
  WantedBy=multi-user.target
  EOL
  chroot "${CHROOT}" systemctl enable powertop.service

  return $SUCCESS
}

install_desktop_environment(){
  title "[+] Installing Desktop Environment"
  chroot "${CHROOT}" pacman -S i3 lightdm lightdm-gtk-greeter --noconfirm
  chroot "${CHROOT}" systemctl enable lightdm.service
  return $SUCCESS
}

install_packages(){
  title "Installing Regularly use Packages"
  #install stuff like graphics (Intel integrated graphics)
  chroot "${CHROOT}" pacman -S xf86-input-synaptics --noconfirm
  chroot "${CHROOT}" pacman -S xorg --noconfirm
  chroot "${CHROOT}" pacman -S lib32-mesa-libgl --noconfirm
  chroot "${CHROOT}" pacman -S firefox --noconfirm
  chroot "${CHROOT}" pacman -S libreoffice --noconfirm
  chroot "${CHROOT}" pacman -S bleachbit --noconfirm
  chroot "${CHROOT}" pacman -S yaourt --noconfirm
  chroot "${CHROOT}" pacman -S evince --noconfirm
  chroot "${CHROOT}" pacman -S alsa pulseaudio --noconfirm
  chroot "${CHROOT}" pacman -S nautilus --noconfirm

  #install Java
  chroot "${CHROOT}" pacman -S jre7-openjdk-headless jre7-openjdk jdk7-openjdk openjdk7-doc openjdk7-src jre8-openjdk-headless jre8-openjdk jdk8-openjdk openjdk8-doc openjdk8-src java-openjfx java-openjfx-doc java-openjfx-src --noconfirm

  #install networkmanager
  chroot "${CHROOT}" pacman -S networkmanager networkmanager-openconnect networkmanager-openvpn networkmanager-pptp networkmanager-vpnc wpa_supplicant wireless_tools dialog net-tools --noconfirm
  chroot "${CHROOT}" pacman -S network-manager-applet nm-connection-editor --noconfirm
  chroot "${CHOORT}" systemctl enable NetworkManager.service

  #Networking
  chroot "${CHROOT}" pacman -S tor --noconfirm
  chroot "${CHROOT}" pacman -S macchanger --noconfirm

  #FireWall
  chroot "${CHROOT}" pacman -S ufw --noconfirm

  #Virtualization
  chroot "${CHROOT}" pacman -S qemu qemu-arch-extra --noconfirm

  #Install i3 desktop environment
  install_desktop_environment

  #install_yubikey
  #sleep_clear 1

  add_bash_config
  sleep_clear 1

  install_powertop
  sleep_clear 1

  return $SUCCESS
}

after_chroot(){
  #Uncomment the language
  chroot "${CHROOT}" pacman -Syy vim --noconfirm
  chroot "${CHROOT}" pacman -Syy wget git --noconfirm
  chroot "${CHROOT}" sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
  chroot "${CHROOT}" locale-gen
  chroot "${CHROOT}" echo LANG=en_US.UTF-8 > /etc/locale.conf
  chroot "${CHROOT}" export LANG=en_US.UTF-8

  #Change Time
  chroot "${CHROOT}" ln -s /usr/share/zoneinfo/US/Central > /etc/localtime
  chroot "${CHROOT}" hwclock --systohc --utc

  #add host name
  ask_hostname
  chroot "${CHROOT}" echo "${HOST_NAME}" > /etc/hostname

  #uncomment Include=/etc/pacman.d/mirrorlist
  update_pacman
  sleep_clear 1

  #Installing Blackarch linux Tools
  chroot "${CHROOT}" wget -O strap.sh http://blackarch.org/strap.sh
  chroot "${CHROOT}" chmod 777 strap.sh
  chroot "${CHROOT}" ./strap.sh
  chroot "${CHROOT}" shred -n 30 -uvz strap.sh

  title "[+] User Creation"
  chroot "${CHROOT}" passwd

  wprintf "Enter Normal User username: "
  chroot "${CHROOT}" read NORMAL_USER
  chroot "${CHROOT}" useradd -m -g users -G wheel,games,power,optical,storage,scanner,lp,audio,video -s /bin/bash "${NORMAL_USER}"
  chroot "${CHROOT}" passwd "${NORMAL_USER}"

  #Uncomment %wheel ALL=(ALL) ALL
  chroot "${CHROOT}" EDITOR=vim visudo
  chroot "${CHROOT}" pacman -S bash-completion --noconfrim

  #Install Boot loader
  title "Syslinux Creation"
  chroot "${CHROOT}" pacman -S gptfdisk syslinux --noconfirm
  chroot "${CHROOT}" syslinux-install_update -iam
  chroot "${CHROOT}" cat > /boot/syslinux/syslinux.cfg << "EOF"
  DEFAULT arch
  Label arch
 	  LINUX ../vmlinuz-linux
 	  APPEND cryptdevice=/dev/sda2:root root=/dev/mapper/root rw ipv6.disable=1
  	INITRD ../initramfs-linux.img
  EOF

  chroot "${CHROOT}" vim /etc/mkinitcpio.conf
  chroot "${CHROOT}" pacman -S f2fs-tools btrfs-progs --noconfirm
  chroot "${CHROOT}" mkinitcpio -p linux

  sleep_clear 1
  install_packages

  umount -Rv "${CHROOT}"
  cryptsetup close "${CRYPT_ROOT}"
  return $SUCCESS
}

main(){
  before_chroot
  sleep_clear 1

  after_chroot
  sleep_clear 1

  printf "Installation Complete"

  return $SUCCESS
}

main "${@}"
