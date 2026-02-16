# 🚀 Quick Setup Firebase Jadwal ke kontrol_1

## ✅ Yang Sudah Diupdate

1. ✅ **Worker.js** - Sekarang pakai path `/kontrol_1`
2. ✅ **jadwal_service.dart** - Flutter app pakai path `/kontrol_1`
3. ✅ **Setup script** - Script untuk push data otomatis ke Firebase

## 🔥 Cara Setup Data ke Firebase

### Opsi 1: Via Script (Recommended - Otomatis)

Jalankan script untuk langsung push data ke Firebase:

```bash
cd f:\ApsGo\ApsGo\railway-worker
node setup-firebase-jadwal.js
```

Script akan:
- ✅ Connect ke Firebase kamu
- ✅ Push data jadwal ke `/kontrol_1`
- ✅ Setup 5 jadwal (3 aktif, 2 nonaktif)
- ✅ Log summary hasil setup

**Output yang diharapkan:**
```
🚀 Starting Firebase setup...
📍 Path: /kontrol_1
✅ Firebase setup completed successfully!
📊 Summary:
   - Path: /kontrol_1
   - Mode Waktu: ENABLED
   - Total Jadwal: 5
   - Jadwal Aktif: 3

📝 Jadwal yang di-setup:
   ✅ jadwal_1: 08:00 → Pot [1, 2, 3] (60s)
   ✅ jadwal_2: 09:00 → Pot [4, 5] (45s)
   ✅ jadwal_3: 16:00 → Pot [1, 2, 3, 4, 5] (30s)
   ❌ jadwal_4: 12:00 → Pot [2, 4] (40s)
   ❌ jadwal_5: 18:00 → Pot [1, 5] (50s)

🎉 Done! Data sudah tersimpan di Firebase.
```

### Opsi 2: Manual via Firebase Console

1. Buka [Firebase Console](https://console.firebase.google.com)
2. Pilih project ApsGo
3. Klik **Realtime Database**
4. Klik `+` untuk add new node
5. Name: `kontrol_1`
6. Copy-paste JSON dari `firebase-structure-complete.json`

## 📱 Test Flutter App

Setelah data di-setup, test Flutter app:

```bash
cd f:\ApsGo\ApsGo
flutter pub get
flutter run
```

**Test checklist:**
- [ ] Buka tab **Kontrol**
- [ ] Tap button **Waktu**
- [ ] Lihat list jadwal (harus ada 5 jadwal)
- [ ] Toggle mode waktu on/off
- [ ] Tambah jadwal baru
- [ ] Edit jadwal existing
- [ ] Delete jadwal

## 🔄 Deploy ke Railway

Setelah verify lokal OK, push ke Railway:

```bash
cd railway-worker
git add .
git commit -m "feat: Update to use kontrol_1 path + flexible jadwal system"
git push origin main
```

Railway akan auto-deploy dalam 2-3 menit.

## 📊 Verify di Railway Logs

Setelah deploy, check logs Railway:

```
🚀 Starting ApsGo Railway Worker...
📍 Kontrol Path: /kontrol_1
✅ Firebase /kontrol_1 readable - waktu mode: ENABLED
📋 Total Jadwal: 3
✅ jadwal_1: 08:00 → Pot [1, 2, 3] 
✅ jadwal_2: 09:00 → Pot [4, 5]
✅ jadwal_3: 16:00 → Pot [1, 2, 3, 4, 5]
```

## ⚠️ Troubleshooting

### Script error: "Firebase initialization failed"

**Check:**
1. File `.env` ada di folder `railway-worker`?
2. Environment variables lengkap?
   ```
   FIREBASE_PROJECT_ID=...
   FIREBASE_CLIENT_EMAIL=...
   FIREBASE_PRIVATE_KEY=...
   FIREBASE_DATABASE_URL=...
   ```

### Flutter app: "No jadwal found"

**Check:**
1. Path di `jadwal_service.dart` = `kontrol_1`? ✅ (sudah diupdate)
2. Data sudah di-push ke Firebase?
3. Firebase rules allow read?

### Worker tidak detect jadwal

**Check:**
1. Worker sudah redeploy dengan code terbaru?
2. Path di worker = `kontrol_1`? ✅ (sudah diupdate)
3. Railway logs show path `/kontrol_1`?

## 🔧 Ubah Path Kembali ke /kontrol

Jika mau pakai path `/kontrol` (bukan `/kontrol_1`):

**Worker.js:**
```javascript
const FIREBASE_PATHS = {
  kontrol: 'kontrol',  // Ubah dari 'kontrol_1' ke 'kontrol'
```

**jadwal_service.dart:**
```dart
static const String kontrolPath = 'kontrol';  // Ubah dari 'kontrol_1'
```

**Setup script:**
```javascript
await db.ref('kontrol').set(kontrolData);  // Ubah dari 'kontrol_1'
```

## 📋 Summary Changes

**Files modified:**
- ✅ `railway-worker/worker.js` - Added FIREBASE_PATHS constant, updated all refs
- ✅ `lib/services/jadwal_service.dart` - Updated path to kontrol_1
- ✅ `railway-worker/setup-firebase-jadwal.js` - New script untuk setup

**Data structure:**
```
Firebase Root
├── aktuator/
├── data/
├── history/
├── kontrol/          ← Your existing data (unchanged)
└── kontrol_1/        ← New data with flexible jadwal
    ├── waktu: true
    ├── sensor: false
    ├── jadwal_1/
    ├── jadwal_2/
    └── jadwal_3/
```

## 🎯 Next Steps

1. ✅ Run setup script: `node setup-firebase-jadwal.js`
2. ✅ Verify data di Firebase Console
3. ✅ Test Flutter app locally
4. ✅ Commit & push to Railway
5. ✅ Monitor Railway logs
6. ✅ Test jadwal trigger di waktu yang ditentukan

---

**Ready to go!** 🚀🌱

Jika ada error atau pertanyaan, check logs atau tanya!
