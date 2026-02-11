# 🚨 SOLUSI LENGKAP: Penjadwalan Tidak Masuk Railway

## 📋 HASIL ANALISIS

### ✅ Yang SUDAH BENAR:
1. **Flutter Code** - Data penjadwalan ditulis dengan benar ke Firebase
2. **Worker Code** - Logic membaca dan execute sudah benar
3. **Format Data** - Compatible antara Flutter dan Worker
4. **Git Repository** - railway-worker sudah di-commit dan push

### ❌ KEMUNGKINAN MASALAH:
1. **Railway Root Directory belum di-set**
2. **Environment Variables belum lengkap/salah**
3. **Redis service belum di-add ke Railway**
4. **Data penjadwalan belum di-set dari Flutter**

---

## 🔧 LANGKAH PERBAIKAN (STEP-BY-STEP)

### **STEP 1: Verifikasi Data Di Firebase Console**

1. Buka [Firebase Console](https://console.firebase.google.com)
2. Pilih project: **project-ta-951b4**
3. Klik **Realtime Database** di sidebar
4. Cek path `/kontrol/`

**Yang HARUS ADA:**
```json
{
  "kontrol": {
    "waktu": true,              ← MUST BE TRUE!
    "waktu_1": "07:30",        ← Format HH:mm string
    "waktu_2": "17:00",        ← Format HH:mm string
    "durasi_1": 60,            ← Integer (seconds)
    "durasi_2": 60,            ← Integer (seconds)
    "otomatis": false,
    "batas_bawah": 40,
    "batas_atas": 100
  }
}
```

**Jika data TIDAK ADA atau `waktu` = false:**
- Buka Flutter app
- Masuk ke **Kontrol Waktu**
- Set jadwal
- **Toggle "Aktif" menjadi ON**
- Klik **Simpan**

---

### **STEP 2: Test Firebase Connection Dari Local**

Di folder railway-worker, buat file `.env`:

```bash
cd f:\ApsGo\ApsGo\railway-worker
```

Create `.env` file (copy dari .env.example):
```env
FIREBASE_PROJECT_ID=project-ta-951b4
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@project-ta-951b4.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYourKeyHere\n-----END PRIVATE KEY-----\n"
FIREBASE_DATABASE_URL=https://project-ta-951b4-default-rtdb.firebaseio.com
```

**Cara dapat Firebase credentials:**
1. Firebase Console → Project Settings
2. Service Accounts tab
3. Klik "Generate New Private Key"
4. Download JSON file
5. Copy value dari JSON:
   - `project_id` → FIREBASE_PROJECT_ID
   - `client_email` → FIREBASE_CLIENT_EMAIL
   - `private_key` → FIREBASE_PRIVATE_KEY (ganti \n dengan \\n)
   - Database URL bisa dari Realtime Database page

**Test connection:**
```powershell
cd railway-worker
npm install
node test-firebase-connection.js
```

**Expected output:**
```
✅ Firebase initialized
✅ DATA FOUND! Structure:
✅ DATA STRUCTURE VALID
✅ WAKTU MODE ENABLED
```

**Jika error:**
- Check credentials (terutama PRIVATE_KEY format)
- Pastikan Database URL benar
- Pastikan Firebase Rules mengizinkan read/write

---

### **STEP 3: Setup Railway - Root Directory**

1. **Login ke Railway:** https://railway.app
2. **Select Project:** mellow-cat
3. **Select Service:** myreppril
4. **Klik tab "Settings"**
5. **Scroll ke section "Build"**
6. **Cari field "Root Directory"**
7. **Isi dengan:** `railway-worker`
8. **Save** (auto-save)

**PENTING:** Tanpa ini, Railway akan build dari root folder dan gagal!

---

### **STEP 4: Add Redis Database**

1. Di Railway project dashboard
2. Klik tombol **"+ New"**
3. Pilih **"Database"**
4. Pilih **"Add Redis"**
5. Tunggu provisioning selesai

Railway akan auto-inject environment variables:
- `REDIS_HOST`
- `REDIS_PORT`
- `REDIS_PASSWORD`

---

### **STEP 5: Set Environment Variables**

Di Railway → Service myreppril → Tab **"Variables"**

**ADD THESE:**

| Variable Name | Value |
|--------------|-------|
| `FIREBASE_PROJECT_ID` | `project-ta-951b4` |
| `FIREBASE_CLIENT_EMAIL` | `firebase-adminsdk-xxxxx@project-ta-951b4.iam.gserviceaccount.com` |
| `FIREBASE_PRIVATE_KEY` | `-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----` |
| `FIREBASE_DATABASE_URL` | `https://project-ta-951b4-default-rtdb.firebaseio.com` |

**⚠️ PENTING untuk PRIVATE_KEY:**
- Harus dalam format string dengan `\n` (backslash-n), BUKAN newline sebenarnya
- Contoh: `-----BEGIN PRIVATE KEY-----\nMIIEvQIBADA...\n-----END PRIVATE KEY-----\n`
- Copy dari JSON file service account, tapi ganti newline dengan `\n`

**Cara mudah:**
```javascript
// Di PowerShell atau Node.js console
const fs = require('fs');
const key = JSON.parse(fs.readFileSync('service-account.json')).private_key;
console.log(key); // Ini sudah format dengan \n
```

---

### **STEP 6: Redeploy Railway**

1. Setelah set Root Directory & Variables
2. Klik tab **"Deployments"**
3. Klik **"Redeploy"** atau biarkan auto-deploy
4. Tunggu build selesai (2-3 menit)

---

### **STEP 7: Monitor Logs**

1. Klik tab **"Logs"** (di navigation bar atas)
2. Enable "Follow logs" (toggle di kanan atas)

**Expected logs saat startup:**
```
🚀 Starting ApsGo Railway Worker...
📡 Firebase Project: project-ta-951b4
📦 Redis: redis.railway.internal:6379
✅ Firebase Admin initialized
✅ Redis connected
✅ Waktu Mode scheduler started (check every 30s)
✅ Sensor Mode monitoring started
✨ ApsGo Railway Worker is running!
```

**Jika ada error:**
- `Firebase initialization failed` → Check credentials
- `Redis error` → Pastikan Redis database sudah di-add
- `Cannot find module` → Check Root Directory setting

---

### **STEP 8: Test Penjadwalan**

**Cara 1: Set jadwal dekat waktu sekarang**
1. Buka Flutter app
2. Kontrol Waktu → Set Jadwal 1 = (waktu sekarang + 2 menit)
3. Durasi = 10 detik
4. **Toggle "Aktif" = ON**
5. Simpan
6. Tunggu 2 menit
7. Cek Railway logs

**Expected di logs:**
```
🕐 JADWAL 1 TRIGGERED: 14:30
   📌 Added to queue: jadwal_1_2026-02-10_14:30
💧 Processing Job: jadwal_1_...
   Type: waktu_jadwal_1
   Pots: [1, 2, 3, 4, 5]
   Duration: 10s
   🔛 Turning ON: mosvet_1, mosvet_3, mosvet_4, mosvet_5, mosvet_6, mosvet_7
   ⏳ Waiting 10s...
   🔚 Turning OFF: mosvet_1, mosvet_3, mosvet_4, mosvet_5, mosvet_6, mosvet_7
✅ Worker completed job jadwal_1_...
   📊 History logged: 2026-02-10 14:30
```

**Cara 2: Check Firebase langsung**
1. Firebase Console → Realtime Database
2. Monitor path `/kontrol/waktu`
3. Monitor path `/aktuator/` (harus berubah dari false → true → false)

---

## 🐛 TROUBLESHOOTING CHECKLIST

### ❌ "No logs at all in Railway"
- [ ] Root directory = `railway-worker`?
- [ ] Environment variables complete?
- [ ] Redis database added?
- [ ] Check Deployments tab for build errors

### ❌ "Logs show but no schedule triggers"
- [ ] Firebase `/kontrol/waktu` = true?
- [ ] Jadwal sudah di-set di Flutter?
- [ ] Format waktu benar (HH:mm string)?
- [ ] Current time match jadwal?

### ❌ "Firebase initialization failed"
- [ ] FIREBASE_PRIVATE_KEY format benar (dengan \n)?
- [ ] SERVICE_ACCOUNT email benar?
- [ ] Database URL benar?
- [ ] Firebase Rules allow read/write?

### ❌ "Redis connection error"
- [ ] Redis database sudah di-add di Railway?
- [ ] REDIS_HOST/PORT/PASSWORD auto-injected?

---

## 📊 CARA CEK DATA FIREBASE DARI FLUTTER

Tambahkan button debug di Flutter (temporary):

```dart
ElevatedButton(
  onPressed: () async {
    final data = await FirebaseDatabase.instance.ref('kontrol').get();
    print('KONTROL DATA: ${data.value}');
  },
  child: Text('Debug: Print Kontrol Data'),
)
```

Check debug console untuk melihat data yang tersimpan.

---

## 🎯 QUICK TEST SCRIPT

Jalankan dari terminal:

```powershell
# Test 1: Check Firebase data
cd f:\ApsGo\ApsGo\railway-worker
node test-firebase-connection.js

# Test 2: Check queue (if worker running)
node check-queue.js
```

---

## 📞 LANGKAH SELANJUTNYA

Setelah mengikuti STEP 1-8:

1. **Screenshot Railway Logs** yang muncul
2. **Screenshot Firebase Console** (path /kontrol/)
3. **Screenshot Railway Settings** (Root Directory & Variables)

Dengan screenshot tersebut, saya bisa bantu troubleshoot lebih lanjut jika masih ada masalah!

---

## ✅ CHECKLIST FINAL

Sebelum test:
- [ ] Data jadwal ada di Firebase `/kontrol/`
- [ ] `waktu` = true di Firebase
- [ ] Railway root directory = `railway-worker`
- [ ] 4 Firebase env variables di Railway
- [ ] Redis database added di Railway
- [ ] Worker logs muncul di Railway
- [ ] Jadwal set 2-3 menit dari sekarang untuk test

**Jika semua checked, penjadwalan PASTI jalan!** ✨
