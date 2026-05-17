# proxmox-server-automated-backup-to-NAS
Implementasi sistem cadangan otomatis (Disaster Recovery) untuk infrastruktur Home Lab berbasis **Proxmox VE**, **TrueNAS**, dan **Syncthing**. Proyek ini menjamin cadangan data server meskipun terjadi **failure** terhadap perangkat Proxmox VE .

---

## 🏗️ Architecture & Workflow

Sistem ini mengikuti aturan **3-2-1 Backup Rule**:
1. **3 Copies of Data:** (Produksi, Local NAS, Remote Laptop).
2. **2 Different Media:** (Internal SSD Server, External HDD Seagate).
3. **1 Off-site/Offline Copy:** (Sinkronisasi ke Laptop Pribadi).

**Alur Kerja:**
1. **Proxmox** melakukan backup VM/LXC terjadwal ke **TrueNAS** melalui protokol **NFS**.
2. **Script Bash kustom** mencadangkan konfigurasi Proxmox (`/etc/pve`, `/etc/network/interfaces`) ke datasets terpisah di TrueNAS secara terjadwal via **Crontab**.
3. **Syncthing** secara otomatis menyinkronkan seluruh folder backup dari TrueNAS ke **Storage Laptop Pribadi** melalui jaringan lokal secara real-time dengan metode *P2P Sync*.

---

## 🛠️ Tech Stack
* **Hypervisor:** Proxmox VE
* **Storage Server:** TrueNAS (File System: ZFS)
* **File Protocols:** NFS (Backup VM), SMB (Mobile/Laptop Access)
* **Automation:** Bash Scripting & Crontab
* **Sync Tool:** Syncthing

---

## Implementation Steps

### 1. Storage Provisioning (TrueNAS)
Membuat dataset terpisah pada pool penyimpanan eksternal/internal anda (saya menggunakan HDD Seagate eksternal) untuk mengategorikan jenis backup:
Contoh:
- SEAGATE_STORAGE (Induk)
- `PVE_BACKUPS`  (Induk PVE)
- `PVE_BACKUPS/WEB_SERVER` (Sub/child  Datasets)
- `PVE_BACKUPS/DOCKER`
- `PVE_BACKUPS/PROXMOX_CONFIG`
(Teruskan dan sesuaikan sesuai kondisi kebutuhan anda)

Membuat Shares, UNIX (NFS) Shares:
- Pada bagian NFS Share pilih /mnt/SEAGATE_STORAGE/PVE_BACKUPS
- Pada Advanced Options, opsi Maproot User pilih root dan opsi Maproot Group pilih root atau sesuaikan dengan punya anda
- Save
(Pada bagian NFS ini anda perlu membuat untuk folder induk PVE (PVE_BACKUPS) dan juga semua folder Sub/Child Datasets (PVE_BACKUPS/WEB_SERVER))

### 2. Proxmox Integration
Menghubungkan Proxmox ke TrueNAS menggunakan NFS Share:
- Pada GUI proxmox anda, masuk ke Datacenter, pilih Storage
- Klik Add, pilih NFS
- Isi kolomnya

 ID: Backups-TrueNAS (Sesuaikan dengan milik anda).

 Server: 10.30.0.243 (IP TrueNAS Anda).

 Export: Klik tanda panah bawah, nanti otomatis muncul /mnt/SEAGATE_STORAGE/PVE_BACKUPS.

 Content: Pilih semua atau sesuai kebutuhan anda

 Node: pilih nama node anda yang ingin di backup (misal pve-homelab)

- Klik Save/Add

(Pada bagian ini anda perlu membuat satu persatu untuk semua folder/datasets yang anda buat agar file backup dapat tersimpan sesuai folder yang sudah terorganisir, terutama sesuaikan pada bagian Export dan ID)

Masih di Datacenter, pergi ke menu Backup:

- Klik Add
- Kolom Node, isi dengan node anda yang ingin di Backup
- Kolom Storage, pilih kategori yang telah anda buat sebelumnya tadi (misal Backups-TrueNAS)
- Schedule, sesuaikan dengan keinginan anda (misal pilih everyday  21:00)
- Selection mode, pilih All atau Include selected VMs (sesuaikan dengan kebutuhan anda)
- Compression: Pilih ZSTD (paling cepat dan efisien)
- Mode, pilih Snapshot
- Klik Create

(Pada bagian ini anda perlu membuat hal yang sama untuk semua kategori yang telah anda buat sebelumnya, Terutama ubah pada bagian Storage dan sesuaikan)

### 3. Automation Script & Crontab
Menggunakan script bash untuk mengamankan konfigurasi OS Proxmox yang tidak tercakup dalam backup VM standar.
- **Script:** `scripts/backup-pve-config.sh`
- **Schedule:** `0 0 * * *` (Setiap tengah malam)

**Tools Backup Konfigurasi Proxmox**

Jalankan perintah ini di Shell Proxmox anda:
  
  nano /usr/local/bin/backup-pve-config.sh

Lalu tempel kode yang ada di dalam Folder Scripts di Repository ini (ini akan mem-backup settingan network, user, dan VM list):

Simpan Ctrl + O, Enter, lalu Ctrl + X

Lalu,
Berikan izin dengan:
 
  chmod +x /usr/local/bin/backup-pve-config.sh

Terakhir, agar script jalan otomatis setiap jam 12 malam, ketik crontab -e dan tambahkan baris ini di paling bawah:
  
  0 0 * * * /bin/bash /usr/local/bin/backup-pve-config.sh

  Simpan  Ctrl + O, Enter, lalu Ctrl + X

Untuk test apakah bekerja bisa jalankan perintah ini:
 
  /bin/bash /usr/local/bin/backup-pve-config.sh

Jika tidak ada muncul Error,  dan jika contoh muncul seperti ini:
  
  tar: Removing leading `/' from member names
  
  tar: Removing leading `/' from hard link targets
  
Itu artinya berhasil dijalankan,

Untuk memastikan File Backup sudah ada, jalankan perintah:
  
  ls -lh /mnt/pve/Backup-ProxmoxConfig (Nama kategori Backup-ProxmoxConfig sesuaikan dengan kategori milik anda)

Jika muncul seperti ini (pve-config-2026-05-17.tar.gz), berarti berhasil

  
### 4. Redundancy via Syncthing
Mengonfigurasi Syncthing sebagai jembatan sinkronisasi antara server dan Laptop/PC pribadi. 
- **Mode:** `Receive Only` pada sisi laptop untuk menjaga integritas data di server.
- **Koneksi:** Terkunci melalui alamat IP statis untuk stabilitas maksimal.

---

## 📸 Project Preview
*(Pastikan nama file di bawah ini sesuai dengan yang Anda upload di folder screenshots)*
- **Dataset Structure:** ![TrueNAS](./screenshots/truenas-datasets.png)
- **Proxmox Storage:** ![PVE](./screenshots/proxmox-nfs.png)
- **Sync Status:** ![Syncthing](./screenshots/syncthing-success.png)
