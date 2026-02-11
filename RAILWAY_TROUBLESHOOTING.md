# ❌ Railway Worker Troubleshooting Guide

## Masalah: Jadwal tidak berjalan, tidak ada log di Railway

### ✅ Langkah Diagnosis:

#### 1. Check Railway Worker Status
Di Railway Dashboard:
- Masuk ke project ApsGo
- Klik service **worker** 
- Tab **Deployments** → Lihat status deployment terakhir
- Tab **Logs** → Periksa apakah worker running

**Expected logs:**
```
🚀 Starting ApsGo Railway Worker...
📡 Firebase Project: project-ta-951b4
📦 Redis: xxxx:6379
⏰ Timezone: Asia/Jakarta (Current: 11/02/2026 14:30:00)
✅ All required environment variables are set
✅ Firebase Admin initialized
✅ Redis connected
✨ ApsGo Railway Worker is running!
```

#### 2. Test Environment Variables
Di Railway Console, jalankan debug script:
```bash
# Di Railway service console
npm run debug
```

Atau manual check:
- Go to **Variables** tab
- Pastikan ada 4 variables ini:
  - `FIREBASE_PROJECT_ID` = project-ta-951b4
  - `FIREBASE_CLIENT_EMAIL` = firebase-adminsdk-xxxxx@project-ta-951b4.iam.gserviceaccount.com
  - `FIREBASE_PRIVATE_KEY` = "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
  - `FIREBASE_DATABASE_URL` = https://project-ta-951b4-default-rtdb.firebaseio.com

#### 3. Test Firebase Configuration
Check apakah Flutter app berhasil menyimpan jadwal:
- Buka Firebase Console → Realtime Database
- Check node `/kontrol`
- Harus ada data seperti:
```json
{
  "waktu": true,
  "waktu_1": "08:00",
  "waktu_2": "16:00",
  "durasi_1": 600,
  "durasi_2": 600
}
```

#### 4. Time Sync Check
- Railway Worker menggunakan timezone Asia/Jakarta
- Check apakah jadwal yang di-set di Flutter sesuai dengan waktu sekarang
- Test dengan set jadwal 1-2 menit dari waktu sekarang

---

## 🛠️ Solusi untuk Masalah Umum

### Problem: "Firebase initialization failed"
**Cause:** Environment variables salah/kurang

**Solution:** 
1. Re-download Service Account Key dari Firebase Console
2. Extract 4 values yang dibutuhkan 
3. Set ulang variables di Railway
4. **PENTING:** `FIREBASE_PRIVATE_KEY` harus dalam quotes dan dengan `\n` escaped

### Problem: "Redis connection error" 
**Cause:** Redis service tidak active

**Solution:**
1. Railway Dashboard → Add Redis Database
2. Link ke worker service
3. Restart worker

### Problem: "Worker tidak trigger jadwal"
**Cause:** Timezone mismatch atau konfigurasi salah

**Solution:**
1. Check `/kontrol` di Firebase ada data
2. Check `waktu: true` 
3. Check jadwal format "HH:MM" (e.g., "08:00")
4. Test dengan jadwal dekat waktu sekarang

### Problem: "No logs di Railway"
**Cause:** Worker crash saat startup

**Solution:**
1. Check **Deployments** tab - ada error saat build?
2. Check **Logs** tab - ada error message?
3. Run debug script: `npm run debug`

---

## 🔍 Debug Commands

### Local Debug (di komputer Anda)
```bash
cd railway-worker
npm install
node debug.js
```

### Railway Debug (di Railway Console)
```bash
npm run debug
```

### Manual Test (di Railway Console)
```bash
# Check environment
env | grep FIREBASE

# Test Firebase connection 
node -e "console.log('DB URL:', process.env.FIREBASE_DATABASE_URL)"

# Test current time
node -e "console.log('Time:', new Date().toLocaleString('id-ID', {timeZone: 'Asia/Jakarta'}))"
```

---

## ⚡ Quick Fix Checklist

- [ ] Railway worker service running (green status)
- [ ] All 4 Firebase environment variables set correctly
- [ ] Redis database service added and linked  
- [ ] Firebase Realtime Database rules allow admin access
- [ ] Flutter app successfully saved schedule (`/kontrol` node exists)
- [ ] Timezone configured as Asia/Jakarta
- [ ] Test schedule set within 1-2 minutes from current time

---

## 📞 Still Having Issues?

1. Export Railway logs: **Logs** tab → Copy all logs
2. Export Firebase `/kontrol` data: Firebase Console → Export JSON  
3. Screenshot Flutter schedule configuration
4. Run `npm run debug` dan copy output

With this information, the issue can be diagnosed precisely.