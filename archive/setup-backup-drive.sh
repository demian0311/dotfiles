#!/usr/bin/env bash
#
# ARCHIVED 2026-10-03: already run on anchor (fstab entry + backup-home.timer
# present). Kept for a rebuild only. Not executable on purpose.
#
# One-time root setup for home backups on anchor.  2026-09-20.
#
#   1. installs restic + exfatprogs
#   2. ERASES the external Seagate and formats it exFAT (readable on macOS)
#   3. adds an /etc/fstab automount at /mnt/backup
#
# THIS DESTROYS EVERYTHING ON THE EXTERNAL DRIVE.
# It refuses to run unless the drive's serial matches the one surveyed.
#
set -euo pipefail

EXPECT_SERIAL="NA7KM91T"
EXPECT_MODEL="BUP Slim Mac SL"
DISK=/dev/sdb
PART=/dev/sdb1
LABEL=ANCHORBKP
MOUNT=/mnt/backup

die() { printf '\n[ABORT] %s\n' "$*" >&2; exit 1; }
say() { printf '\n== %s\n' "$*"; }

[ "$(id -u)" -eq 0 ] || die "run with sudo"

say "Verifying the target disk is the external Seagate, not your system disk"
serial=$(lsblk -dno SERIAL "$DISK" 2>/dev/null || true)
model=$(lsblk -dno MODEL  "$DISK" 2>/dev/null || true)
tran=$(lsblk -dno TRAN    "$DISK" 2>/dev/null || true)
printf '   device : %s\n   model  : %s\n   serial : %s\n   bus    : %s\n' \
       "$DISK" "$model" "$serial" "$tran"

[ "$serial" = "$EXPECT_SERIAL" ] || die "serial is '$serial', expected '$EXPECT_SERIAL'. The drive may have been re-plugged as a different device node. Re-run lsblk and check before changing DISK= in this script."
[ "$model"  = "$EXPECT_MODEL"  ] || die "model is '$model', expected '$EXPECT_MODEL'"
[ "$tran"   = "usb" ]            || die "transport is '$tran', expected usb"

root_src=$(findmnt -no SOURCE / | sed 's/\[.*//')
root_disk=$(lsblk -nsro NAME,TYPE "$root_src" | awk '$2=="disk"{print $1}' | tail -1)
[ -n "$root_disk" ] || die "could not work out which physical disk holds /"
printf '   / lives on: /dev/%s\n' "$root_disk"
[ "/dev/$root_disk" != "$DISK" ] || die "$DISK is the disk holding /"

if findmnt -S "$DISK" >/dev/null 2>&1 || findmnt "$DISK"* >/dev/null 2>&1; then
  die "something on $DISK is mounted; unmount it first"
fi

say "Current contents of $DISK (all of this will be erased)"
lsblk -o NAME,SIZE,FSTYPE,LABEL "$DISK"

printf '\nType ERASE to wipe %s and format it exFAT: ' "$DISK"
read -r answer
[ "$answer" = "ERASE" ] || die "not confirmed"

say "Installing restic, exfatprogs and gptfdisk"
pacman -S --needed --noconfirm restic exfatprogs gptfdisk

say "Ensuring the exFAT kernel module loads at boot"
printf 'exfat\n' > /etc/modules-load.d/exfat.conf
modprobe exfat

say "Wiping partition table on $DISK"
wipefs -a "$DISK"
partprobe "$DISK" 2>/dev/null || true
sleep 2

say "Creating one GPT partition spanning the disk"
sgdisk --zap-all "$DISK" >/dev/null
sgdisk --new=1:0:0 --typecode=1:0700 --change-name=1:"$LABEL" "$DISK"
partprobe "$DISK"
sleep 2
[ -b "$PART" ] || die "$PART did not appear after partitioning"

say "Formatting $PART as exFAT, label $LABEL"
mkfs.exfat -L "$LABEL" "$PART"

uuid=$(blkid -s UUID -o value "$PART")
[ -n "$uuid" ] || die "could not read the new filesystem UUID"
say "New filesystem UUID: $uuid"

say "Adding the automount entry to /etc/fstab"
cp -a /etc/fstab "/etc/fstab.bak.$(date +%Y%m%d-%H%M%S)"
sed -i '\#[[:space:]]/mnt/backup[[:space:]]#d' /etc/fstab
command cat >> /etc/fstab <<FSTAB

# External backup drive (Seagate BUP Slim, exFAT) - added 2026-09-20.
# noauto + x-systemd.automount: mounts on first access, never blocks boot
# when the drive is unplugged.
UUID=$uuid  $MOUNT  exfat  noauto,x-systemd.automount,x-systemd.idle-timeout=600,nofail,uid=1000,gid=1000,umask=0022,noatime  0 0
FSTAB

mkdir -p "$MOUNT"
systemctl daemon-reload
systemctl restart local-fs.target 2>/dev/null || true

say "Mounting and testing write access as demian"
ls "$MOUNT" >/dev/null 2>&1 || true
sleep 2
mountpoint -q "$MOUNT" || mount "$MOUNT"
mountpoint -q "$MOUNT" || die "could not mount $MOUNT"
sudo -u demian touch "$MOUNT/.write-test" || die "demian cannot write to $MOUNT"
rm -f "$MOUNT/.write-test"

df -h "$MOUNT"
say "Done. Now run, as your normal user (no sudo):"
printf '\n    backup-init && backup-home\n\n'
