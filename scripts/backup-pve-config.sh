#!/bin/bash
# Ubah Folder tujuan sesuai storage yang Anda buat di Proxmox
DEST="/mnt/pve/Backup-ProxmoxConfig"
DATE=$(date +%Y-%m-%d)

# Backup folder konfigurasi proxmox
tar -czf $DEST/pve-config-$DATE.tar.gz /etc/pve /etc/network/interfaces /etc/hosts /etc/fstab /etc/resolv.conf

# Hapus backup lama (lebih dari 30 hari) agar storage tidak penuh
find $DEST -type f -mtime +30 -delete
