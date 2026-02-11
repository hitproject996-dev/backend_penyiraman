# 🚨 URGENT: Railway Worker Setup - Step by Step

## ❌ Masalah: Tidak Ada Log di Railway

Berdasarkan screenshot Firebase Anda, **data kontrol sudah BENAR** ✅:
```json
{
  "waktu": true,
  "waktu_1": "06:41",
  "waktu_2": "16:38",
  "durasi_1": 600,
  "durasi_2": 104
}
```

**Root Cause:** Railway Worker belum running atau tidak bisa akses Firebase.

---

## ✅ SOLUSI LENGKAP

### 🎯 Opsi 1: Test Lokal Dulu (RECOMMENDED)

Sebelum deploy ke Railway, test koneksi Firebase di komputer Anda:

#### Step 1: Download Firebase Service Account Key

1. Buka [Firebase Console](https://console.firebase.google.com)
2. Pilih project **Project TA** (project-ta-951b4)
3. Klik ⚙️ **Project Settings** (pojok kiri bawah)
4. Tab **Service Accounts**
5. Klik **Generate New Private Key**
6. Download file JSON (jangan share ke siapapun!)

#### Step 2: Setup Environment Variables Lokal

1. Buka file JSON yang di-download
2. Copy 3 nilai ini:
   ```json
   {
     "project_id": "project-ta-951b4",
     "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
     "client_email": "firebase-adminsdk-xxxxx@project-ta-951b4.iam.gserviceaccount.com"
   }
   ```

3. Buat file `.env` di folder `railway-worker/`:
   ```bash
   cd f:\ApsGo\ApsGo\railway-worker
   copy .env.template .env
   notepad .env
   ```

4. Isi dengan credentials dari JSON:
   ```env
   FIREBASE_PROJECT_ID=project-ta-951b4
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@project-ta-951b4.iam.gserviceaccount.com
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEv...\n-----END PRIVATE KEY-----\n"
   FIREBASE_DATABASE_URL=https://project-ta-951b4-default-rtdb.firebaseio.com
   ```

   **PENTING untuk FIREBASE_PRIVATE_KEY:**
   - Harus ada quotes: `"..."`
   - Harus ada `\n` di awal dan akhir
   - Jangan ubah format dari JSON

#### Step 3: Test Koneksi Firebase

```powershell
cd f:\ApsGo\ApsGo\railway-worker
npm run test:firebase
```

**Expected output:**
```
✅ All required environment variables are set
✅ Firebase Admin SDK initialized
✅ Successfully read /kontrol data
✅ Waktu mode is ENABLED
✅ Jadwal 1: 06:41
✅ Jadwal 2: 16:38
```

**Jika berhasil:**
- Credentials Anda benar ✅
- Firebase accessible ✅
- Siap deploy ke Railway ✅

**Jika error:**
- Check private key format (harus ada quotes dan \n)
- Check client email benar
- Check Firebase Database rules allow admin access

#### Step 4: Test Worker Lokal (Optional)

Jika koneksi OK, test worker secara lokal:

```powershell
# Install Redis lokal (optional, skip jika tidak punya)
# Atau comment out Redis parts di worker.js untuk test

# Run worker
npm run dev
```

Tunggu sampai waktu schedule (06:41 atau 16:38), worker akan trigger otomatis.

---

### 🎯 Opsi 2: Deploy Langsung ke Railway

Jika test lokal berhasil, deploy ke Railway:

#### Step 1: Commit Changes

```powershell
cd f:\ApsGo\ApsGo
git add .
git commit -m "Update Railway Worker configuration"
git push origin main
```

#### Step 2: Setup Railway Environment Variables

1. Login ke [Railway Dashboard](https://railway.app)
2. Pilih project ApsGo
3. Klik service **worker**
4. Tab **Variables**
5. Tambahkan 4 variables (gunakan nilai yang sama dari .env lokal):

| Variable | Value |
|----------|-------|
| `FIREBASE_PROJECT_ID` | `project-ta-951b4` |
| `FIREBASE_CLIENT_EMAIL` | `firebase-adminsdk-xxxxx@project-ta-951b4.iam.gserviceaccount.com` |
| `FIREBASE_PRIVATE_KEY` | `"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"` |
| `FIREBASE_DATABASE_URL` | `https://project-ta-951b4-default-rtdb.firebaseio.com` |

**CRITICAL:** Copy-paste EXACT values from your working local .env file!

#### Step 3: Redeploy

Railway will auto-redeploy after adding variables, or manually:
1. Tab **Deployments**
2. Klik **...** (three dots)
3. **Redeploy**

#### Step 4: Check Logs

Tab **Logs**, expected output:
```
🚀 Starting ApsGo Railway Worker...
✅ All required environment variables are set
✅ Firebase Admin initialized
✅ Redis connected
✨ ApsGo Railway Worker is running!
⏰ Checking scheduled watering...
```

---

## 🔍 Quick Troubleshooting

### Error: "Missing environment variables"
→ .env file tidak ada atau belum diisi
→ **Fix:** Ikuti Step 2 di atas

### Error: "Firebase initialization failed"
→ Private key format salah
→ **Fix:** Copy EXACT value dari JSON, dengan quotes dan \n

### Error: "PERMISSION_DENIED"
→ Firebase rules tidak allow service account
→ **Fix:** Check Firebase Realtime Database Rules

### No Error, tapi No Logs
→ Worker belum deploy/running
→ **Fix:** Check Railway Deployments tab

---

## 📊 Verifikasi Data Firebase (From Your Screenshot)

✅ Your Firebase data is **CORRECT**:
```
kontrol/
  ├─ waktu: true              ✅ Mode enabled
  ├─ waktu_1: "06:41"         ✅ Schedule 1
  ├─ waktu_2: "16:38"         ✅ Schedule 2  
  ├─ durasi_1: 600            ✅ 10 minutes
  ├─ durasi_2: 104            ✅ 1.7 minutes
  ├─ batas_atas: 80           ✅ Sensor threshold
  ├─ batas_bawah: 50          ✅
  ├─ otomatis: false          ℹ️ Sensor mode disabled
  └─ mode_sensor: "smart"     ✅
```

**Flutter app sudah benar!** Masalahnya di Railway Worker yang belum running.

---

## 🎯 Next Steps

**MULAI DARI SINI:**

1. ✅ Test koneksi Firebase lokal:
   ```powershell
   cd f:\ApsGo\ApsGo\railway-worker
   npm run test:firebase
   ```

2. ✅ Jika berhasil, deploy ke Railway (ikuti Opsi 2)

3. ✅ Monitor Railway logs

4. ✅ Test dengan set jadwal 2-3 menit dari sekarang

---

## 📞 Need Help?

Jika masih stuck:
1. Screenshot output dari `npm run test:firebase`
2. Screenshot Railway logs (jika sudah deploy)
3. Screenshot Firebase Service Account settings

Mari kita debug bersama!