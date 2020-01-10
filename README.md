# Arch Linux Install Script

**I DESIGNED THIS FOR ME AND ONLY ME**

```
git clone htttps://github.com/EasyIP2023/arch-linux-install-script.git
```

**Before arch-chroot**
```
# FIRST Thing Wipe Drive
# shred --verbose --random-source=/dev/urandom --iterations=3 /dev/sda
# Part Drive
parted -a optimal /dev/sda mklabel gpt mkpart primary 0% 257Mib name 1 boot mkpart primary 257Mib 100% name 2 root
mkfs.btrfs -L boot /dev/sda1
cryptsetup --verbose --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat /dev/sda2
cryptsetup open --type luks /dev/sda2 r00t
mkfs.f2fs -l root /dev/mapper/r00t
mount -v /dev/mapper/r00t /mnt
mkdir -v /mnt/boot
mount -v /dev/sda1 /mnt/boot
vim /etc/pacman.d/mirrorlist
pacstrap -i /mnt base base-devel
genfstab -U -p /mnt >> /mnt/etc/fstab
arch-chroot /mnt
pacman -S vim --noconfirm
pacman -S wget git curl --noconfirm
```

**After arch-chroot**
```
# Replace ExecStart=... with ExecStart=-/usr/bin/agetty --autologin <username> --noclear %I $TERM
vim /mnt/etc/systemd/system/getty.target.wants/getty@tty1.service

umount -Rv /mnt
cryptsetup close r00t
```
