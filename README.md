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
- SEAGATE_STORAGE
- `PVE_BACKUPS`
- `PVE_BACKUPS/WEB_SERVER`
- `PVE_BACKUPS/DOCKER`
- `PVE_BACKUPS/PROXMOX_CONFIG`
(Teruskan dan sesuaikan kondisi kebutuhan anda)

### 2. Hypervisor Integration
Menghubungkan Proxmox ke TrueNAS menggunakan NFS Share dengan opsi `vzdump` content type. Hal ini memungkinkan Proxmox mengenali NAS sebagai target backup resmi.

### 3. Automation Script & Crontab
Menggunakan script bash untuk mengamankan konfigurasi OS Proxmox yang tidak tercakup dalam backup VM standar.
- **Script:** `scripts/backup-pve-config.sh`
- **Schedule:** `0 0 * * *` (Setiap tengah malam).

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
