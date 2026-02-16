# 🔥 Setup Firebase untuk Sistem Jadwal Baru

## 📋 Copy Struktur Ini ke Firebase

Buka Firebase Console → Realtime Database → Edit `/kontrol` node:

```json
{
  "batas_atas": 32,
  "batas_bawah": 11,
  "durasi_sensor": 600,
  "mode_sensor": "smart",
  "otomatis": true,
  "sensor": false,
  "waktu": true,
  
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
  },
  
  "jadwal_3": {
    "aktif": true,
    "waktu": "16:00",
    "durasi": 30,
    "pot_aktif": [1, 2, 3, 4, 5],
    "pompa_air": true,
    "pompa_pupuk": true
  }
}
```

## 🎯 Contoh Sesuai Request Kamu

**Kebutuhan:**
- Jam 8 pagi: Pot 1, 2, 3 aktif
- Jam 9 pagi: Pot 4, 5 aktif
- Jam 4 sore: Pot 1, 2, 3, 4, 5 aktif

**Setup Firebase:**

```json
{
  "waktu": true,
  
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
    "durasi": 60,
    "pot_aktif": [4, 5],
    "pompa_air": true,
    "pompa_pupuk": true
  },
  
  "jadwal_3": {
    "aktif": true,
    "waktu": "16:00",
    "durasi": 60,
    "pot_aktif": [1, 2, 3, 4, 5],
    "pompa_air": true,
    "pompa_pupuk": true
  }
}
```

## ➕ Cara Tambah Jadwal Baru di Firebase

### Via Firebase Console (Manual)

1. Buka Firebase Console
2. Go to Realtime Database
3. Navigate ke `/kontrol`
4. Click `+` untuk add child
5. Name: `jadwal_4`
6. Add children:

```
jadwal_4:
  ├─ aktif: true
  ├─ waktu: "12:00"
  ├─ durasi: 45
  ├─ pot_aktif: [2, 4]
  ├─ pompa_air: true
  └─ pompa_pupuk: false
```

### Via Flutter App (Recommended)

1. Buka ApsGo App
2. Tap **Kontrol** tab
3. Tap **Waktu** button
4. Tap tombol **+ Tambah Jadwal**
5. Isi form sesuai kebutuhan
6. Tap **TAMBAH JADWAL**

**Keuntungan via App:**
- ✅ Lebih mudah & cepat
- ✅ Auto validasi
- ✅ Auto generate ID
- ✅ Visual pot selection
- ✅ Time picker

## 📱 Cara Test di App

### 1. Run Flutter App

```bash
cd f:\ApsGo\ApsGo
flutter run
```

### 2. Navigate ke Jadwal

1. Login ke app
2. Tap tab **Kontrol** di bottom navigation
3. Tap button **Waktu**
4. Akan muncul **Jadwal Management Page**

### 3. Test Features

- ✅ Lihat semua jadwal
- ✅ Toggle mode waktu on/off
- ✅ Tambah jadwal baru
- ✅ Edit jadwal
- ✅ Toggle jadwal aktif/nonaktif
- ✅ Duplikat jadwal
- ✅ Hapus jadwal
- ✅ Pull to refresh

## 🔄 Migration dari Format Lama

### Format Lama Kamu (di screenshot):

```json
{
  "waktu": true,
  "waktu_1": "10:02",
  "durasi_1": 60,
  "waktu_2": "16:00",
  "durasi_2": 600
}
```

### Konversi ke Format Baru:

```json
{
  "waktu": true,
  
  "jadwal_1": {
    "aktif": true,
    "waktu": "10:02",
    "durasi": 60,
    "pot_aktif": [1, 2, 3, 4, 5],
    "pompa_air": true,
    "pompa_pupuk": true
  },
  
  "jadwal_2": {
    "aktif": true,
    "waktu": "16:00",
    "durasi": 600,
    "pot_aktif": [1, 2, 3, 4, 5],
    "pompa_air": true,
    "pompa_pupuk": true
  }
}
```

**Note:** Format lama masih jalan di worker (backward compatible), jadi tidak perlu buru-buru migrate.

## ⚙️ Field Explanations

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `aktif` | boolean | No | `true` | Enable/disable jadwal |
| `waktu` | string | Yes | - | Format "HH:MM" (08:00, 16:00, dll) |
| `durasi` | number | No | `60` | Durasi dalam DETIK |
| `pot_aktif` | array | Yes | - | Array pot: [1, 2, 3, 4, 5] |
| `pompa_air` | boolean | No | `true` | Nyalakan pompa air |
| `pompa_pupuk` | boolean | No | `false` | Nyalakan pompa pupuk |

## ✅ Validation Rules

Firebase akan accept jadwal jika:

1. ✅ `waktu` format "HH:MM" dengan 2 digit
2. ✅ `durasi` > 0
3. ✅ `pot_aktif` tidak kosong
4. ✅ `pot_aktif` berisi angka 1-5

Worker akan skip jadwal jika:
- ❌ `aktif` = false
- ❌ `pot_aktif` kosong
- ❌ `waktu` format salah

## 🚀 Deploy Changes

### 1. Update Flutter App

```bash
cd f:\ApsGo\ApsGo
flutter pub get
flutter build apk --release
```

### 2. Update Railway Worker (Sudah Done!)

Worker sudah updated dan di-push ke GitHub.

### 3. Setup Firebase

Copy struktur JSON di atas ke Firebase Console.

### 4. Test Everything

1. Test add jadwal via app
2. Test edit jadwal
3. Test toggle aktif/nonaktif
4. Wait sampai waktu jadwal
5. Check logs Railway untuk verifikasi

## 📊 Expected Logs Railway

Setelah setup, di Railway logs kamu akan lihat:

```
⏱️  CHECK #15: 08:00:05 | Mode: ✅
📋 Total Jadwal: 3
✅ jadwal_1: 08:00 → Pot [1, 2, 3] 🔔 MATCH!
✅ jadwal_2: 09:00 → Pot [4, 5]
✅ jadwal_3: 16:00 → Pot [1, 2, 3, 4, 5]

🕐 JADWAL_1 TRIGGERED: 08:00
   🎯 Pot aktif: [1, 2, 3]
   ⏱️  Durasi: 60s
   💧 Pompa Air: ON
   🌿 Pompa Pupuk: OFF
   ✅ Successfully added to queue
```

## 🎉 You're All Set!

Sistem penjadwalan baru siap digunakan! Fitur:

✅ Multiple jadwal (unlimited)  
✅ Flexible pot selection  
✅ Per-schedule configuration  
✅ Easy add/edit/delete via app  
✅ Real-time sync  
✅ Auto validation  

**Next Steps:**
1. Setup Firebase dengan struktur di atas
2. Run Flutter app
3. Test tambah/edit jadwal
4. Monitor Railway logs
5. Enjoy! 🚀🌱
