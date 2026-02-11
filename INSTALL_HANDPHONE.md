# 📱 Cara Install ApsGo di Handphone

## ✅ APK Sudah Selesai Di-build!

Lokasi APK: `f:\ApsGo\ApsGo\build\app\outputs\flutter-apk\app-release.apk`

---

## 🔧 Cara Install di Handphone

### **Metode 1: Transfer via USB Cable**

1. **Sambungkan HP ke PC** dengan kabel USB
2. **Copy file APK** dari:
   ```
   f:\ApsGo\ApsGo\build\app\outputs\flutter-apk\app-release.apk
   ```
3. **Paste ke HP** (folder Download atau Internal Storage)
4. **Buka File Manager** di HP
5. **Tap file** `app-release.apk`
6. **Izinkan install** dari Unknown Sources (jika diminta)
7. **Install** → Selesai!

---

### **Metode 2: Transfer via WhatsApp/Telegram**

1. **Kirim file APK** ke diri sendiri via WhatsApp/Telegram:
   - Buka WhatsApp Web/Desktop
   - Kirim ke chat pribadi Anda
   - File: `app-release.apk`
   
2. **Buka di HP** → Download file
3. **Tap file APK** → Install

---

### **Metode 3: Upload ke Google Drive**

1. **Upload APK** ke Google Drive dari PC
2. **Buka Google Drive** di HP
3. **Download APK**
4. **Install**

---

## ⚙️ Setting HP (Penting!)

Sebelum install, aktifkan **Install from Unknown Sources**:

### **Android 8.0+:**
1. Settings → Apps & notifications
2. Special app access
3. Install unknown apps
4. Pilih File Manager/Chrome
5. Allow from this source → ON

### **Android 7.0 dan lebih lama:**
1. Settings → Security
2. Unknown sources → ON

---

## 🔑 Login ke Aplikasi

Setelah install:

1. **Buka app ApsGo**
2. **Login** dengan:
   - Email: (akun Firebase Anda)
   - Password: (password akun)
   
3. **Atau Register** akun baru

---

## 📡 Koneksi ke ESP32

Pastikan:
- ✅ HP dan ESP32 sama-sama **terkoneksi internet**
- ✅ ESP32 sudah **tersambung ke WiFi**
- ✅ Firebase Realtime Database sudah **dikonfigurasi**

Data akan sync otomatis via Firebase!

---

## 🐛 Troubleshooting

**"App not installed":**
- Uninstall versi lama (jika ada)
- Coba install ulang

**"Unknown sources blocked":**
- Ikuti langkah Setting HP di atas

**"App keeps crashing":**
- Pastikan Google Services sudah aktif di HP
- Check koneksi internet

---

## 🔄 Update App

Jika ada update:
1. Build APK baru: `flutter build apk --release`
2. Transfer & install (akan replace versi lama)

---

## 📦 Informasi APK

- **Nama:** ApsGo (Project TA)
- **Package:** com.example.project_ta
- **Size:** ± 20-30 MB
- **Min Android:** 5.0 (Lollipop)
- **Firebase:** Integrated

---

**Selamat mencoba! 🎉**
