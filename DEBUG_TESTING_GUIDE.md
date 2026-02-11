# 🧪 **DEBUG MODE TESTING GUIDE**

## **Langkah Testing untuk Diagnosa Log Issue**

### **STEP 1: Test Flutter App dengan Debug Console**

1. **Buka Flutter App di Debug Mode**
   ```bash
   cd f:\ApsGo\ApsGo
   flutter run --debug
   ```

2. **Lihat Debug Console Output**
   - Buka VS Code Debug Console atau Terminal
   - Perhatikan log output saat save configuration

### **STEP 2: Test Waktu Mode Setting**

1. **Di Flutter App:**
   - Buka **Kontrol** → **Waktu Mode**
   - Set jadwal 2-3 menit dari sekarang
   - **PASTIKAN toggle "Waktu Mode" AKTIF** ✅
   - Set durasi: 10 detik
   - Klik **SIMPAN**

2. **Yang Harus Muncul di Console:**
   ```
   🔧 [DEBUG] Starting save configuration...
   ✅ [DEBUG] Local storage saved
   📊 [DEBUG] Config to Firebase: {waktu_1: 14:30, waktu_2: 18:00, durasi_1: 10, durasi_2: 600, waktu: true}
   🔥 [DEBUG] Updating Firebase kontrol config: ...
   ✅ [DEBUG] Firebase config saved successfully
   🚀 [DEBUG] Starting Waktu Mode automation...
   ✅ [DEBUG] Waktu Mode started
   ```

### **STEP 3: Cek Railway Logs**

1. **Buka Railway Dashboard**
   - Pergi ke: https://railway.app/dashboard
   - Pilih project: **myreppril**
   - Klik **Deploy Logs**

2. **Yang Harus Muncul Setiap 30 Detik:**
   ```
   ⏰ [DEBUG] Checking scheduled watering... 2026-02-10T...
   📊 [DEBUG] Retrieved kontrol config: {
     "waktu_1": "14:30",
     "waktu_2": "18:00", 
     "durasi_1": 10,
     "durasi_2": 600,
     "waktu": true
   }
   🕐 [DEBUG] Current time: 14:28, Date: 2026-02-10
   📅 [DEBUG] Scheduled times - Jadwal 1: 14:30, Jadwal 2: 18:00
   ⏰ [DEBUG] Jadwal 1 time mismatch - Expected: 14:30, Current: 14:28
   ```

3. **Saat Jadwal Trigger (di waktu yang tepat):**
   ```
   🕐 JADWAL 1 TRIGGERED: 14:30
   📌 Added to queue: jadwal_1_2026-02-10_14:30
   
   💧 Processing Job: jadwal_1_2026-02-10_14:30
   Type: waktu_jadwal_1
   Pots: [1, 2, 3, 4, 5]
   Duration: 10s
   🔛 Turning ON: mosvet_1, mosvet_2, mosvet_3, mosvet_4...
   ```

---

## 🚨 **KEMUNGKINAN MASALAH & SOLUSI**

### **Jika Flutter Debug Log Tidak Muncul:**
- ❌ **Firebase connection issue**
- ✅ **Cek internet connection**
- ✅ **Restart app dengan `flutter clean && flutter run`**

### **Jika Railway Log Tidak Update:**
- ❌ **Environment variables salah**
- ❌ **Firebase project tidak match**
- ✅ **Re-deploy Railway worker**

### **Jika Config Tersimpan tapi Worker Tidak Jalan:**
- ❌ **Toggle "Waktu Mode" tidak aktif**
- ❌ **Jadwal time format salah**
- ✅ **Pastikan format waktu "HH:mm" (contoh: "14:30")**

---

## 📱 **QUICK FIX CHECKLIST**

- [ ] Toggle "Waktu Mode" sudah **AKTIF** ✅
- [ ] Format waktu sudah benar (HH:mm)
- [ ] Flutter app berjalan dalam debug mode
- [ ] Railway worker masih running (cek status online)
- [ ] Firebase project sama (project-ta-951b4)
- [ ] Internet connection stabil