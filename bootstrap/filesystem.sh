#!/bin/bash

pacman -Sy --noconfirm --needed git
git clone https://github.com/ryanpcadams/dotfiles.git
source dotfiles/bootstrap/config

# Pacman config
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
sed -Ei "s/^#(ParallelDownloads).*/\1 = 5/;/^#Color$/s/#//" /etc/pacman.conf

# Set up mirrors
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

mkdir /mnt &>/dev/null
umount -A --recursive /mnt
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

# sgdisk -n 1::+300M --typecode=1:ef00 --change-name=1:'BOOT' ${DISK}
# sgdisk -n 2::+24G --typecode=2:8200 --change-name=2:'SWAP' ${DISK}
# sgdisk -n 3::+25G --typecode=3:8304 --change-name=3:'ROOT' ${DISK}
# sgdisk -n 4::-0 --typecode=4:8302 --change-name=4:'HOME' ${DISK}
# partprobe ${DISK} # reread partition table to ensure it is correct
# mkfs.fat -F 32 "${DISK}1"
# mkswap "${DISK}2"
# mkfs.ext4 "${DISK}3"
# mkfs.ext4 "${DISK}4"
# swapon "${DISK}2"
# mount "${DISK}3" /mnt
# mount --mkdir "${DISK}1" /mnt/boot
# mount --mkdir "${DISK}4" /mnt/home

partprobe ${DISK} # reread partition table to ensure it is correct
mkfs.fat -F 32 "${DISK}5"
mkswap "${DISK}6"
mkfs.ext4 "${DISK}7"
mkfs.ext4 "${DISK}8"
swapon "${DISK}6"
mount "${DISK}7" /mnt
mount --mkdir "${DISK}5" /mnt/boot
mount --mkdir "${DISK}1" /mnt/boot/efi
mount --mkdir "${DISK}8" /mnt/home

pacstrap /mnt base base-devel linux linux-firmware zsh git curl ca-certificates networkmanager grub efibootmgr os-prober
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
genfstab -L /mnt >> /mnt/etc/fstab

pacman -S --noconfirm --needed stow
mkdir -p /mnt/home/$user_name
cp -r dotfiles /mnt/home/$user_name
stow --dir=/mnt/home/$user_name/dotfiles .

echo "root:${root_pwd}" | chpasswd
