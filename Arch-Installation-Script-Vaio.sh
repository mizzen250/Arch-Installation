#!/bin/bash
##
##
##

## Make Log
touch /root/install.Log
echo "" > /root/install.log;echo "" >> /root/install.log;
echo -n "Started at: " >> /root/install.log; date >> /root/install.log
echo "" >> /root/install.log;echo "" >> /root/install.log;
export ok=true

echo ""
echo "================================================================="
echo "               Installation Script - For Vaio"
echo "================================================================="
echo ""
echo "Hey This script was written for a specific computer but you're welcome to use it"

## Setting up Wifi
echo -n "Set up wifi success" >> /root/install.log    && \
date >> /root/install.log                             && \
wifi-menu                                             || \
export ok=false
[[ $ok != true ]] && echo "Failed to setup wifi" >> /root/install.log && return

## Update system clock
echo "Update System Clock" >> /root/install.log       && \
timedatectl set-ntp true                              || \
export ok=false

## Partition Disks
echo "24:Partition Disks"
parted -s /dev/sda mklabel gpt                        && \
parted -s /dev/sda mkpart P1 1MiB 2MiB                && \
parted -s /dev/sda mkpart P1 ext4 2MiB 202MiB         && \
parted -s /dev/sda mkpart P1 202MiB 1GiB              && \
parted -s /dev/sda mkpart P1 ext4 1GiB 100%           && \
parted -s /dev/sda set 1 bios_grub on                 || \
export ok=false
[[ $ok != true ]] && echo "Failed to Partition Disks properly" && return

## Format Partitions
echo "34:Formatting Partitions"
mkfs.ext4 /dev/sda2                                   && \
mkfs.ext4 /devsda4                                    && \
mkswap /dev/sda3                                      || \
return

## Mount fs
echo "41:Mounting fs"                                 && \
mount /dev/sda4 /mnt                                  && \
swapon /dev/sda3                                      && \
mkdir /mnt/boot                                       && \
mount /dev/sda2 /mnt/boot                             || \
return

## Selecting Mirrors
echo "49:Selecting Mirrors"
cd /etc/pacman.d/                                     && \
curl "https://www.archlinux.org/mirrorlist/?country=CA&country=US&protocol=https&ip_version=4"    | \
sed -i 's/^#Server/Server/' > mirrorlist              && \
cd                                                    || \
return


## Install Base Packages
echo "58:pacstrap"
pacstrap /mnt base base-devel                         || \
return

## Generate fsTab
echo "63:Genfstab"
genfstab -U /mnt >> /mnt/etc/fstab                    || \
return

## Chroot
echo "68:chroot"
arch-chroot /mnt                                      || \
return

## Enter Timezone
echo "73:Timezone"
#ln -sf /usr/share/zoneinfo/Canada/Pacific
ln -sf /usr/share/zoneinfo/UTC                        || \
return


## Run hwclock to generate /etc/adjtime
echo "80:Creating /etc/adjtime"
hwclock --systohc                                     || \
return

## Localization
echo "85:Localization"
cd /etc                                               && \
mv locale.gen locale.gen.bu                           && \
echo "## Modified By Tim" > locale.gen                && \
echo "## Backup located at /etc/locale.gen.bu" >> locale.gen  && \
echo "## " >> locale.gen                              && \
echo "en_US.UTF-8 UTF-8" >> locale.gen                && \
locale-gen                                            && \
echo "LANG=en_US.UTF-8" > locale.conf                 || \
return

## Network Configuration
echo "97:Setting /etc/hostname"
echo "TimsVaio" > hostname                            || \
return

echo "101:Editing /etc/hosts"
echo "127.0.0.1   localhost" >> hosts                 && \
echo "127.0.1.1   TimsVaio.localdomain   TimsVaio" >> hosts || \
return
echo ""

## Root passwd
echo "108:User Accounts"
echo "!!! Setting Up User Accounts !!!"               && \
echo "Enter Root Passwd"                              && \
passwd                                                || \
return

## Setup sutime
echo "115:sutime"
echo ""; echo "!!! sutime"                            && \
useradd -mG wheel -s /bin/bash sutime                 && \
echo "!!! Enter Password"                             && \
passwd sutime                                         || \
return

## Setup tim
echo "123:tim"
echo ""; echo "!!! tim"
useradd -ms /bin/bash time                            && \
echo "!!! Enter Password"                             && \
passwd tim                                            || \
return

echo ""; echo "!!! K, It's time to Edit the sudoers file"
sleep 1
visudo
return

## Install System Stuff
echo "135:"
pacman -S --noconfirm exfat-utils thermald i7z cpupower || \
return

## Install Boot Stuff
echo "140:"
pacman -S --noconfirm grub intel-ucode sddm xorg      || \
return

## Install Network Stuff
echo "145:"
pacman -S --noconfirm networkmanager bluez dialog     || \
return

## Install Odds and Ends
echo "150:"
pacman -S --noconfirm cowsay vim mc htop mlocate      || \
return

## Install Printer stuff
echo "155:"
pacman -S --noconfirm cups cups-pdf samba             || \
return

## Install Pacman Stuff
pacman -S --noconfirm pacman-contrib pkgstats         || \
return

## Install Security Stuff
pacman -S --noconfirm rkhunter                        || \
return
     
     
## GRUB
grub-install --target=i386-pc /dev/sda                && \
grub-mkconfig -o /boot/grub/grub.cfg                  || \
return

## Update mlocate db
updatedb                                              || \
return

## Setup paccache
systemctl enable paccache.timer                       && \
paccache -rk2                                         && \
paccache -ruk0                                        || \
return

## Set Up sddm
systemctl enable sddm.service                         || \
return

## Enable thermald
systemctl enable thermald.service                     || \
return

## Enable cpupower
systemctl enable cpupower.service                     || \
return

## Enable CUPS Service
systemctl enable org.cups.cupsd.service               || \
return

## **********    DONT FORGET Samba needs more Configuration  *******
#systemctl enable smb.service

## rkhunter
rkhunter --propupd                                    && \
rkhunter -c --sk                                      || \
return

echo "" >> /root/install.log;echo "" >> /root/install.log;
echo -n "successfully finished at: " >> /root/install.log; date >> /root/install.log
echo "" >> /root/install.log;echo "" >> /root/install.log;
##
##  EOF
##


