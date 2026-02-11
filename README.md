# ApsGo - Sistem Penjadwalan Penyiraman Otomatis

Aplikasi Flutter untuk kontrol otomatis sistem penyiraman tanaman berbasis IoT dengan Firebase Realtime Database dan Railway Worker.

## Status Terkini

✅ **Sistem berjalan real-time dengan delay 20 detik/section**
⚠️ **Catatan:** 1 waktu penjadwalan digunakan untuk banyak pompa sekaligus

## Komponen Sistem

### 1. Flutter Mobile App
- Kontrol manual aktuator (pompa & mosvet)
- Penjadwalan otomatis (waktu mode)
- Monitoring sensor real-time
- History logging

### 2. Railway Worker (Node.js)
- Background automation 24/7
- Scheduler dengan timezone Asia/Jakarta
- Firebase SDK dengan REST API fallback
- BullMQ job queue untuk reliability
- Auto-recovery dari timeout issues

## Fitur Utama

- **Dual Mode**: Kontrol manual + penjadwalan otomatis
- **Real-time Sync**: Firebase Realtime Database
- **Reliable Execution**: Timeout handling + REST API fallback
- **History Tracking**: Log semua aktivitas penyiraman
- **Safety Mechanisms**: Auto-shutoff jika error

## Teknologi

- **Frontend**: Flutter (Dart)
- **Backend Worker**: Node.js v18+ 
- **Database**: Firebase Realtime Database
- **Queue**: Redis + BullMQ
- **Deployment**: Railway.app
- **Authentication**: Firebase Auth + Google Sign-In

## Getting Started

### Mobile App
```bash
flutter pub get
flutter run
```

### Railway Worker
```bash
cd railway-worker
npm install
node worker.js
```

## Dokumentasi

- [Railway Setup Guide](RAILWAY_QUICK_START.md)
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
- [Debug & Testing Guide](DEBUG_TESTING_GUIDE.md)
- [Troubleshooting](RAILWAY_TROUBLESHOOTING.md)
