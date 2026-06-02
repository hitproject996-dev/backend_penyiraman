# Dokumentasi Perubahan Mode Penyiraman
## Serial Bergiliran dengan Break 30 Detik

**Tanggal Update:** June 2, 2026  
**Versi:** 2.0 - Sequential Mode

---

## 📋 Ringkasan Perubahan

Sistem penyiraman telah diubah dari **mode paralel** menjadi **mode serial bergiliran**:

### Sebelumnya (Paralel)
```
Jam 06:00 → Pot 1, Pot 2, Pot 3 semua ON bersamaan
           → Semua tunggu 60 detik
           → Semua OFF bersamaan
Total waktu: 60 detik
```

### Sekarang (Serial Bergiliran)
```
Jam 06:00 → Pot 1 ON
           → Pot 1 tunggu 60 detik
           → Pot 1 OFF
           → Break 30 detik
Jam 06:01 → Pot 2 ON
           → Pot 2 tunggu 60 detik
           → Pot 2 OFF
           → Break 30 detik
Jam 06:02 → Pot 3 ON
           → Pot 3 tunggu 60 detik
           → Pot 3 OFF
Total waktu: 3 menit 40 detik
```

---

## 🎯 Penjelasan Teknis

### 1. Mode Fixed (Durasi Tetap)

**Karakteristik:**
- Setiap pot disiram dengan durasi yang sama (sesuai setting `durasi` jadwal/threshold)
- Pompa air/pupuk tetap ON selama loop (untuk efisiensi aliran)
- Break 30 detik antar pot untuk stabilisasi

**Rumus Total Waktu:**
```
Total = (Jumlah Pot × Durasi Per Pot) + ((Jumlah Pot - 1) × 30 detik)
```

**Contoh:**
- 3 pot, durasi 60s per pot → Total: 180s + 60s = 240 detik (4 menit)
- 5 pot, durasi 120s per pot → Total: 600s + 120s = 720 detik (12 menit)

**Proses Detail untuk 3 Pot:**
```
[06:00:00] Pompa ON + Pot 1 Valve ON
[06:00:60] Pot 1 Valve OFF (pompa tetap ON)
[06:01:00] BREAK - menunggu 30 detik
[06:01:30] Pompa ON + Pot 2 Valve ON
[06:02:30] Pot 2 Valve OFF (pompa tetap ON)
[06:03:00] BREAK - menunggu 30 detik
[06:03:30] Pompa ON + Pot 3 Valve ON
[06:04:30] Pot 3 Valve OFF + Pompa OFF
[06:04:30] ✅ Penyiraman Selesai
```

### 2. Mode Smart (Sensor-Based)

**Karakteristik:**
- Setiap pot dimonitor secara INDIVIDUAL dengan sensornya
- Pot berhenti saat soil moisture mencapai target (batas_atas)
- Maksimal durasi per pot = setting `durasi` (timeout safety)
- Break 30 detik antar pot

**Monitoring Interval:** 2 detik (cek sensor setiap 2 detik)

**Contoh Execution:**
```
[06:00:00] Pompa ON + Pot 1 Valve ON
           → Monitor: 30% < 70% target
[06:00:02] → Monitor: 35% < 70% target
[06:00:04] → Monitor: 40% < 70% target
[06:02:00] → Monitor: 70% == 70% TARGET REACHED! ✅
           Pot 1 Valve OFF (pompa tetap ON)
[06:02:00] BREAK - menunggu 30 detik
[06:02:30] Pompa ON + Pot 2 Valve ON
           → Monitor: 25% < 70% target
[06:02:32] → Monitor: 35% < 70% target
[06:03:30] → Monitor: 70% == 70% TARGET REACHED! ✅
           Pot 2 Valve OFF (pompa tetap ON)
[06:04:00] BREAK - menunggu 30 detik
[06:04:30] Pompa ON + Pot 3 Valve ON
           → Monitor: 28% < 70% target
[06:05:15] → Monitor: 70% == 70% TARGET REACHED! ✅
           Pot 3 Valve OFF + Pompa OFF
[06:05:15] ✅ Penyiraman Selesai
```

**Total waktu smart mode = VARIABLE** (tergantung kecepatan mencapai target)

### 3. Break 30 Detik

**Tujuan:**
- Stabilisasi tanah setelah penyiraman
- Memastikan air merata
- Menunggu sensor stabilisasi
- Meringankan beban pompa

**Durasi:** Tetap 30 detik (tidak dapat dikonfigurasi saat ini)

---

## ⚙️ Implementasi pada Firebase

### Jadwal (Waktu Mode)
```javascript
// Firebase struktur
jadwal_1: {
  aktif: true,
  waktu: "06:00",           // Jam mulai
  pot_aktif: [1, 2, 3],     // Pot yang akan disiram (BERGILIRAN)
  durasi: 60,               // Durasi PER POT (dalam detik)
  pompa_air: true,
  pompa_pupuk: false
}
```

**Contoh eksekusi:**
- Jadwal 1 jam 06:00 dengan pot [1,2,3] durasi 60s
- Dimulai jam 06:00, selesai jam 06:03:40

### Threshold (Sensor Mode)
```javascript
// Firebase struktur
threshold_1: {
  aktif: true,
  pot_aktif: [1, 2, 3],     // Pot yang akan disiram (BERGILIRAN)
  batas_bawah: 30,          // Trigger saat <= 30%
  batas_atas: 70,           // Stop saat >= 70% (per pot)
  durasi: 600,              // Maksimal durasi PER POT (dalam detik)
  smart_mode: true,         // Gunakan sensor monitoring
  pompa_air: true,
  pompa_pupuk: true
}
```

**Contoh eksekusi:**
- Threshold 1 terdeteksi pada pot [1,2,3]
- Pot 1 dimonitor: stop saat 70% (misal 180 detik)
- Break 30 detik
- Pot 2 dimonitor: stop saat 70% (misal 120 detik)
- Break 30 detik
- Pot 3 dimonitor: stop saat 70% (misal 150 detik)
- Total: ~9 menit (variable)

---

## 🔒 Keamanan & Safety

### Mekanisme Safety
1. **Verification setelah ON:** Cek Firebase untuk konfirmasi valve sudah ON
2. **Error Handling:** Jika ada error, semua mosvet (valve) langsung OFF
3. **Timeout Protection:** Smart mode memiliki maksimal durasi per pot
4. **Retry Logic:** Update Firebase dengan retry hingga 3 kali

### Off Command
```
Pompa OFF hanya dilakukan SETELAH semua pot selesai
Ini mencegah pompa mati di tengah penyiraman pot berikutnya
```

---

## 📊 History Logging

### Data yang Dicatat
```javascript
{
  timestamp: 1234567890000,
  source: "server",
  type: "waktu_jadwal_1",           // Tipe penyiraman
  pots: [1, 2, 3],                  // Pot yang disiram
  duration: 240,                    // Total durasi ACTUAL (termasuk break)
  soil_1: 72,                       // Sensor data saat log
  soil_2: 68,
  soil_3: 74
}
```

### Durasi Dicatat
- **Fixed Mode:** Total waktu = (pot × durasi) + ((pot-1) × 30s break)
- **Smart Mode:** Total waktu ACTUAL saat semua pot mencapai target atau timeout

---

## 🚨 Perubahan Perilaku vs Sebelumnya

| Aspek | Sebelumnya | Sekarang |
|-------|-----------|---------|
| **Eksekusi Pot** | Paralel (bersamaan) | Serial (bergiliran) |
| **Break Antar Pot** | Tidak ada | 30 detik |
| **Durasi** | Total untuk semua pot | Per pot |
| **Total Waktu** | Lebih cepat | Lebih lama (~3x) |
| **Efek Pompa** | Beban max | Beban stabil |
| **Sensor Stability** | Kurang akurat | Lebih akurat per-pot |

---

## ⏱️ Estimasi Waktu Eksekusi

### Fixed Mode (60 detik per pot)
```
1 pot  → ~60 detik
2 pot  → ~150 detik (2m 30s)
3 pot  → ~240 detik (4m)
4 pot  → ~330 detik (5m 30s)
5 pot  → ~420 detik (7m)
```

### Smart Mode (Variable)
```
3 pot  → 5-15 menit (tergantung kondisi tanah)
5 pot  → 10-30 menit (tergantung kondisi tanah)
```

---

## 🔔 Notifikasi Perubahan

### Notifikasi Jadwal (Fixed Mode)
```
Sebelumnya:
"Pada jam 06:00 akan dilakukan penyiraman untuk pot 1, 2, 3."

Sekarang:
"Penyiraman bergiliran untuk pot 1, 2, 3 dimulai dari jam 06:00. 
Setiap pot disiram 60s dengan jeda 30 detik."
```

### Notifikasi Threshold (Smart Mode)
Tetap sama, hanya ada penanda "bergiliran" untuk clarity.

---

## 🐛 Troubleshooting

### Jika Penyiraman Tidak Bergiliran
1. Cek Firebase `/kontrol/jadwal_*` atau `/kontrol/threshold_*`
2. Pastikan `pot_aktif` adalah array, bukan single value
3. Cek log: kata kunci "SEQUENTIAL WATERING" harus muncul

### Jika Break 30 Detik Tidak Terjadi
1. Cek log: kata kunci "BREAK 30 DETIK" harus muncul
2. Verifikasi durasi break di kode: `BREAK_BETWEEN_POTS_MS = 30000` (ms)

### Jika Pompa Tidak OFF
1. Cek log untuk error pada langkah terakhir
2. Manual OFF via Firebase `/aktuator/mosvet_1` dan `/aktuator/mosvet_2`

---

## 🔄 Rollback (Kembali ke Paralel)

Jika ingin kembali ke mode paralel, hubungi developer untuk revert perubahan worker.js ke versi sebelumnya.

---

## 📝 Catatan Developer

- Mode bergiliran dipilih untuk: stabilitas sensor, efisiensi pompa, dan kontrol lebih baik
- Break 30 detik hardcoded (bisa dikonfigurasi via env var jika perlu)
- Backward compatible: struktur Firebase tidak berubah
- Tested pada: 1-5 pot configuration

---

**Update Next?** Rencana mungkin:
- [ ] Make break duration configurable
- [ ] Per-pot sensor tolerance tuning
- [ ] Priority-based watering (pot priority order)
- [ ] Concurrent threshold + schedule handling
