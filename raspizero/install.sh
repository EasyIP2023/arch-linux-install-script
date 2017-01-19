#!/bin/bash

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
NC="`tput sgr0`"

#Partitions and Drives
SD_CARD=""
SD_BOOT=""
SD_ROOT=""

CHROOT="root"
BOOT="boot"

#return codes
SUCCESS=1337
FAILURE=31337

err() {
	printf "%s[-] ERROR: %s%s\n" "${RED}" "${@}" "${NC}"
	exit $FAILURE

	return $SUCCESS	 
}
wprintf() {
    fmt="${1}"

    shift
    printf "%s${fmt}%s" "${GREENB}" "${@}" "${NC}"

    return $SUCCESS
}

banner() {
  columns="$(tput cols)"
  str="*********************** Arch Linux Rasberry Pi Zero Installer Script ***************************"

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

sleep_clear() {
    sleep $1
    clear

    return $SUCCESS
}

title() {
	banner
	printf "${GREEN}>> %s${NC}\n\n\n" "${@}"

	return $SUCCESS
}

needed_package() {
	title "[+] Installing needed packages"
	chroot "${CHROOT}" pacman -Syyu --noconfirm
	chroot "${CHROOT}" pacman -S git --noconfirm
	chroot "${CHROOT}" pacman -S wget --noconfirm
	chroot "${CHROOT}" pacman -S alsa-utils --noconfirm

	return $SUCCESS
}

#Install wifi driver for EW-7611ULB dongle
install_wifi() {
	title "[+] Installing Network Drivers"
	#install networkmanager packages
	chroot "${CHROOT}" pacman -S networkmanager networkmanager-openconnect networkmanager-openvpn networkmanager-pptp networkmanager-vpnc wpa_supplicant wireless_tools dialog net-tools --noconfirm

	#Install EW-7611ULB Wifi driver
	chroot "${CHROOT}" git clone https://github.com/lwfinger/rtl8723bu.git
	chroot "${CHROOT}" cd rtl8723bu
	chroot "${CHROOT}" make
	chroot "${CHROOT}" make install
  chroot "${CHROOT}" cd /

	#Enable Netwok Manager Service
	chroot "${CHROOT}" systemctl enable NetworkManager.service
	chroot "${CHROOT}" rm -rf rtl8723bu/ 
	
	return $SUCCESS
} 


#install bluetooth driver for EW-7611ULB dongle
install_bluetooth() {	
	title "[+] Install Bluetooth Drivers "
	chroot "${CHROOT}" pacman -S bluz bluez-utils --noconfrim #install bluetooth packages

	#install Edimax Bluetooth Drivers
	chroot "${CHROOT}" wget http://www.edimax.us/download/drivers/EW-7611ULB/EW-7611ULB_Bluetooth_driver.zip
	chroot "${CHROOT}" unzip EW-7611ULB_Bluetooth_driver.zip
	chroot "${CHROOT}" cd EW-7611ULB_Bluetooth_driver/Linux_BT_USB_v3.1_20150526_8723BU_BTCOEX_20150119-5844_Edimax
	chroot "${CHROOT}" make install -s
	chroot "${CHROOT}" cd /

	#Enable bluetooth 
	chroot "${CHROOT}" modprobe -v 8723bu
	chroot "${CHROOT}" systemctl enable bluetooth.service
	chroot "${CHROOT}" rm -rf EW-7611ULB_Bluetooth_driver/ EW-7611ULB_Bluetooth_driver.zip
	
	return $SUCCESS
}

install_display() {
	chroot "${CHROOT}" pacman -S xf86-video-fbdev --noconfirm
	chroot "${CHROOT}" pacman -S openbox lxde gamin dbus
	chroot "${CHROOT}" pacman -S xorg-server xorg-xinit xorg-server-utils
	chroot "${CHROOT}" pacman -S mesa xf86-video-fbdev xf86-video-vesa
	chroot "${CHROOT}" echo “exec ck-launch-session startlxde” >> ~/.xinitrc
}

print_partitions(){
    i=""

    while true
    do
        title "SD card Setup"
        wprintf "[+] Current Partition table"
        printf "\n
    > /boot     : ${SD_BOOT}
    > /         : ${SD_ROOT}
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

main() {
	title "[+] Installing Arch on Rasberry Pi Zero"
	printf "BEFORE USE - make sure *dosfstools* is install"
	lsblk 
	
	wprintf "[?] Enter name of SD Card ex. (/dev/sdc): "
	read SD_CARD
	
	#Check if user would like to wipe the SD Card
	input=""
	wprintf "[?] Would you like to wipe the drive (MAY TAKE SOME TIME!!!) [y/n]: "
	read input
	if [ "${input}" = "y" -o "${input}" = "Y" ]
	then
		shred --verbose --random-source=/dev/urandom --iterations=3 "${SD_CARD}"
	fi

	#Partition Drive
	wprintf "*** Partiioning SD Card ****\n"
	parted -a optimal -s "${SD_CARD}" mklabel gpt mkpart primary 0% 100Mib name 1 boot mkpart primary 100Mib 100% name 2 root
	
	wprintf "**** Script makes boot /dev/sdX1 and root /dev/sdX2 ****\n"
	lsblk

	wprintf "[?] Boot partition (/dev/sdXY): "
	read SD_BOOT
	wprintf "[?] Root partition (/dev/sdXY): "
	read SD_ROOT
	
	sleep_clear 1

	print_partitions
	sleep_clear 1

	#Create and mount the FAT filesystem
	mkfs.vfat "${SD_BOOT}"
	mkdir "${BOOT}"
	mount "${SD_BOOT}" "${BOOT}"

	#Create and mount the ext4 filesytem
	mkfs.ext4 "${SD_ROOT}"
	mkdir "${CHROOT}"
	mount "${SD_ROOT}" "${CHROOT}"

	sleep 30

	#Download and extract root filesystem
	wprintf "[+] Downloading and extracting root filesystem"
	wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz
	bsdtar -xpf ArchLinuxARM-rpi-latest.tar.gz -C "${CHROOT}"
	sync
	sleep_clear 1

	#move boot files to the first partition
	wprintf "[+] Moving boot files to first partition\n"

	mv ${CHROOT}/boot/* ${BOOT}
	sleep_clear 1

	#needed_packages
	#install_display
	#sleep_clear 1

	#install_wifi
	#sleep_clear 1

	#install_bluetooth
	#sleep_clear 1

	#Unmount and Remove the file systems
	wprintf "[-] Unmounting and Removing"
	umount -R "${BOOT}" "${CHROOT}"
	#find boot/ "${CHROOT}/" -type f -exec shred -n 30 -uvz {} \;
	#rm -rf boot/ "${CHROOT}/"

	wprintf "FINISED!!! :) \n"
	wprintf "************     WRITE DOWN        *********************\n"
	wprintf "************ Default username: alarm *******************\n"
	wprintf "************ Default pass: alarm   *********************\n"
	wprintf "******** Defualt pass for root user is root ************\n"
	wprintf "********************************************************\n"
	wprintf "********************************************************\n"

	return $SUCCESS
}

main "${@}"
