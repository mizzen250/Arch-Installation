#!/bin/bash
##
##
##

## Make Log
export log=/root/install.log
export mirrors="https://www.archlinux.org/mirrorlist/?country=CA&country=US&protocol=https&ip_version=4"
export mirrorlist=/etc/pacman.d/mirrorlist
export ok="good"

logSuccess () {
  echo -en ">>> $1 -- " >> $log && date +/%y/%m/%d-%I:%M:%S >> $log
}

logFail () {
  echo -en "!!! $1 !!! -- " >> $log && date +/%y/%m/%d-%I:%M:%S >> $log && export ok=$2
  # $2 == VVV
  # good
  # bad
  # critical
}

logNote () {
  echo -en "\n NOTE: $1 -- " >> $log && date +/%y/%m/%d-%I:%M:%S >> $log && echo ""
}

logNote "Installation started"

echo -e "\n ================================================================="
echo    "               Installation Script - For Vaio"
echo -e "================================================================= \n"

echo "This script was written for a specific computer but you're welcome to use it"

## Setting up Wifi

echo -en "\n Set up wifi : "; wifi-menu               && \
logSuccess "Wifi Setup Successfull"                   || \
logFail "Wifi Setup Unsuccessfull" "bad"
[[ $ok == "critical" ]] && return


## Update system clock
echo -en "\n Updating system Clock:"
timedatectl set-ntp true                              && \
logSuccess "Update System Clock"                      || \
logFail "Coould not Update System Clock" "bad"
[[ $ok == "critical" ]] && return

## Partition Disks
echo -e "\n Partitioning Disks:"
parted -s /dev/sda mklabel gpt                        && \
parted -s /dev/sda mkpart P1 1MiB 2MiB                && \
parted -s /dev/sda mkpart P1 ext4 2MiB 202MiB         && \
parted -s /dev/sda mkpart P1 202MiB 1GiB              && \
parted -s /dev/sda mkpart P1 ext4 1GiB 100%           && \
parted -s /dev/sda set 1 bios_grub on                 && \
logSuccess "Disks Partitioned"                        || \
logFail "Disks not Partitioned" "critical"
[[ $ok == "critical" ]] && return


## Format Partitions
echo -e "\n Formatting Partitions:"
mkfs.ext4 /dev/sda2                                   && \
mkfs.ext4 /devsda4                                    && \
mkswap /dev/sda3                                      && \
logSuccess "Partitions Formatted"                     || \
logFail "Partitions not Formatted" "critical"
[[ $ok == "critical" ]] && return

## Mount fs
echo -e "\n Mounting fs:"                             && \
mount /dev/sda4 /mnt                                  && \
swapon /dev/sda3                                      && \
mkdir /mnt/boot                                       && \
mount /dev/sda2 /mnt/boot                             && \
logSuccess "successfully mounted fs"                  || \
logFail "Trouble Mounting fs" "critical"
[[ $ok == "critical" ]] && return



## Selecting Mirrors
echo -en "\n Creating mirrorlist"
curl $mirrors | sed -i 's/^#Server/Server/' > $mirrorlist && \
logSuccess "Mirrorlist created"                       || \
logFail "Mirrorlist no created" "critical"
[[ $ok == "critical" ]] && return


## Install Base Packages
echo -en "Installing Base Packages:"
pacstrap /mnt base base-devel                         && \
logSuccess "Disks Partitioned"                        || \
logFail "Disks not Partitioned" "critical"
[[ $ok == "critical" ]] && return

## Generate fsTab
echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab                    && \
logSuccess "Creating fstab"                           || \
logFail "Failed to create fstab" "critical"
[[ $ok == "critical" ]] && return

# setup root
# copy log
# copy scripts
# copy configs
# 
# 


## Chroot
echo "Chrooting"
arch-chroot /mnt                                      && \
logSuccess "Chrooted"                                 || \
logFail "Chroot failed" "critical"
[[ $ok == "critical" ]] && return



###   IN CHROOT ENV     ####



echo -e "\n Welcome Back:"

# Unmounting Partitions
umount -r /mnt; swapoff                               && \
logSuccess "Unmounted Partitions"                     || \
logFail "Failed to unmount Partitions" "critical"
[[ $ok == "critical" ]] && return


# Rebooting

echo -e "\n K, We're finnished... Probably. If there is anything left to clean up, do it now."



echo "" >> /root/install.log;echo "" >> /root/install.log;
echo -n "successfully finished at: " >> /root/install.log; date >> /root/install.log
echo "" >> /root/install.log;echo "" >> /root/install.log;
##
##  EOF
##


