# 📱 Panduan Sistem Penjad walan Baru - Flutter App

## ✨ Fitur Baru

Sistem penjadwalan ApsGo telah diupgrade dengan fitur:

✅ **Multiple Jadwal** - Tidak lagi terbatas 2 jadwal saja  
✅ **Flexible Pot Selection** - Setiap jadwal bisa pilih pot mana yang aktif  
✅ **Per-Schedule Config** - Tiap jadwal punya durasi & pompa sendiri  
✅ **Enable/Disable** - Matikan jadwal tanpa hapus data  
✅ **Real-time Sync** - Langsung sync dengan Firebase & Railway Worker

## 📁 File Baru yang Dibuat

### Models
- `lib/models/jadwal_model.dart` - Data model untuk jadwal

### Services
- `lib/services/jadwal_service.dart` - CRUD operations untuk jadwal Firebase

### Screens
- `lib/screens/jadwal_management_page.dart` - List & manage all jadwal
- `lib/screens/jadwal_form_page.dart` - Add/edit jadwal form

### Config
- `firebase-structure-complete.json` - Struktur Firebase lengkap

## 🗄️ Struktur Firebase Baru

```json
{
  "kontrol": {
    "waktu": true,
    "sensor": false,
    "otomatis": true,
    
    "jadwal_1": {
      "aktif": true,
      "waktu": "08:00",
      "durasi": 60,
      "pot_aktif": [1, 2, 3],
      "pompa_air": true,
      "pompa_pupuk": false
    },
    "jadwal_2": {
      "aktif": true,
      "waktu": "09:00",
      "durasi": 45,
      "pot_aktif": [4, 5],
      "pompa_air": true,
      "pompa_pupuk": true
    }
  }
}
```

## 🚀 Cara Setup

### 1. Copy Struktur Firebase

1. Buka Firebase Console → Realtime Database
2. Edit `/kontrol` node
3. Tambahkan jadwal sesuai contoh di atas
4. Atau import dari `firebase-structure-complete.json`

### 2. Update Dependency (Jika Perlu)

Pastikan `pubspec.yaml` sudah punya:

```yaml
dependencies:
  firebase_database: ^latest_version
  shared_preferences: ^latest_version
```

### 3. Update Navigation

File `lib/screens/kontrol_page.dart` sudah diupdate untuk navigasi ke JadwalManagementPage.

## 📱 Cara Menggunakan di App

### Akses Jadwal Management

1. Buka app ApsGo
2. Tap tab **Kontrol**
3. Tap button **Waktu**
4. Akan muncul **Jadwal Management Page**

### Tambah Jadwal Baru

1. Di Jadwal Management Page, tap tombol **+ Tambah Jadwal**
2. Isi form:
   - **Waktu**: Pilih jam berapa jadwal akan jalan
   - **Durasi**: Berapa menit penyiraman (auto convert ke detik)
   - **Pilih Pot**: Centang pot mana yang akan disiram
   - **Pompa Air**: Toggle on/off
   - **Pompa Pupuk**: Toggle on/off
   - **Status Jadwal**: Aktif or nonaktif
3. Tap **TAMBAH JADWAL**

### Edit Jadwal

1. Di list jadwal, tap button **Edit**
2. Ubah settingan yang diinginkan
3. Tap **SIMPAN PERUBAHAN**

### Aktifkan/Nonaktifkan Jadwal

Gunakan **Switch** di kanan atas setiap jadwal card untuk toggle on/off cepat.

### Duplikat Jadwal

1. Tap button **Duplikat** di jadwal yang ingin dicopy
2. Jadwal baru otomatis dibuat dengan ID baru (status: nonaktif)
3. Edit jadwal baru sesuai kebutuhan

### Hapus Jadwal

1. Tap icon **🗑️** (trash) di jadwal yang ingin dihapus
2. Konfirmasi penghapusan

## 🎨 UI Features

### Jadwal Management Page

- **Mode Waktu Toggle**: Enable/disable semua jadwal sekaligus
- **Jadwal Cards**: Menampilkan semua jadwal dengan info lengkap
- **Color Coding**: Hijau = aktif, Abu-abu = nonaktif
- **Real-time Updates**: Pull to refresh untuk sync terbaru

### Jadwal Form Page

- **Time Picker**: Native Android/iOS time picker
- **Duration Input**: Input menit, auto convert ke detik
- **Pot Selection**: Visual checkboxes untuk 5 pot
- **Quick Actions**: "Pilih Semua" & "Bersihkan"
- **Validation**: Auto validasi sebelum save

## ⚠️ Catatan Penting

### Kompatibilitas dengan Worker

Worker Railway sudah updated untuk support format baru. Kedua sistem (lama & baru) masih compatible:

**Format Lama** (masih jalan):
```json
{
  "waktu_1": "08:00",
  "durasi_1": 60
}
```

**Format Baru** (recommended):
```json
{
  "jadwal_1": {
    "aktif": true,
    "waktu": "08:00",
    "durasi": 60,
    "pot_aktif": [1, 2, 3],
    "pompa_air": true,
    "pompa_pupuk": false
  }
}
```

### Migration Path

Tidak perlu migrate semua sekaligus. Sistem bisa pakai campuran format lama & baru.

**Recommended migration:**
1. Biarkan format lama tetap jalan
2. Tambah jadwal baru dengan format baru
3. Test jadwal baru beberapa hari
4. Hapus format lama setelah yakin

## 🔧 Troubleshooting

### Jadwal tidak muncul di app

**Check:**
1. Firebase connected? (Check Firebase console)
2. Struktur Firebase benar?
3. Node path: `/kontrol/jadwal_X`

### Jadwal tidak trigger di worker

**Check:**
1. Worker running di Railway?
2. `kontrol.waktu` = `true`?
3. `jadwal_X.aktif` = `true`?
4. Format waktu "HH:MM" (2 digit)?
5. Check Railway logs

### Pot tidak menyala

**Check:**
1. `pot_aktif` array benar? `[1, 2, 3]`
2. Pot number 1-5 (bukan 0-4)
3. Check aktuator di Firebase
4. Hardware connection OK?

## 📊 Testing Checklist

Sebelum production, test:

- [ ] Add jadwal baru
- [ ] Edit jadwal existing
- [ ] Toggle jadwal aktif/nonaktif
- [ ] Duplikat jadwal
- [ ] Hapus jadwal
- [ ] Toggle mode waktu on/off
- [ ] Test jadwal trigger di waktu yang ditentukan
- [ ] Test multiple pot selection
- [ ] Test pompa air on/off per jadwal
- [ ] Test pompa pupuk on/off per jadwal
- [ ] Test pull to refresh
- [ ] Test dengan 5+ jadwal sekaligus

## 🎯 Contoh Use Case

### Use Case 1: Rumah simple

**Kebutuhan**: Siram semua pot 2x sehari (pagi & sore)

**Setup**:
```
Jadwal 1: 08:00 → Pot [1,2,3,4,5] → 60s
Jadwal 2: 16:00 → Pot [1,2,3,4,5] → 60s
```

### Use Case 2: Per-pot berbeda

**Kebutuhan**:
- Pot 1&2: 3x sehari (pagi, siang, sore)
- Pot 3&4: 2x sehari (pagi, sore)
- Pot 5: 1x sehari (pagi)

**Setup**:
```
Jadwal 1: 07:00 → Pot [1,2] → 60s
Jadwal 2: 08:00 → Pot [3,4,5] → 60s  
Jadwal 3: 12:00 → Pot [1,2] → 45s
Jadwal 4: 16:00 → Pot [3,4] → 50s
Jadwal 5: 17:00 → Pot [1,2] → 40s
```

### Use Case 3: Different durations

**Kebutuhan**: Setiap pot punya durasi berbeda

**Setup**:
```
Jadwal 1: 08:00 → Pot [1] → 30s (Fast)
Jadwal 2: 08:05 → Pot [2] → 60s (Medium)
Jadwal 3: 08:10 → Pot [3] → 90s (Long)
Jadwal 4: 08:15 → Pot [4] → 45s
Jadwal 5: 08:20 → Pot [5] → 75s
```

## 📝 Best Practices

1. **Naming Convention**: Gunakan `jadwal_1`, `jadwal_2`, dst (agar auto-detect worker)
2. **Time Format**: Selalu 2 digit "HH:MM" (misal: "08:00" bukan "8:0")
3. **Duration**: Input dalam menit di app, akan auto convert ke detik
4. **pot_aktif**: Gunakan array number [1, 2, 3], bukan string
5. **Testing**: Test jadwal baru dengan status nonaktif dulu sebelum aktifkan

## 🔗 Related Files

- Worker: `railway-worker/worker.js` (sudah updated)
- Firebase Guide: `railway-worker/FLEXIBLE_SCHEDULE_GUIDE.md`
- Example Firebase: `firebase-structure-complete.json`

---

## 💡 Tips

- Gunakan **Duplikat** untuk cepat bikin jadwal mirip
- **Pull to refresh** untuk sync perubahan dari Firebase/Worker
- **Mode Waktu toggle** untuk disable semua jadwal sekaligus
- Jadwal dengan **pot kosong** akan di-skip otomatis

Selamat menggunakan sistem penjadwalan baru! 🚀🌱
