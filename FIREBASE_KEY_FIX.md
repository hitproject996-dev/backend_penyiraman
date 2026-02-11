# 🔥 Firebase Private Key Error - Quick Fix

## ❌ Error: "Failed to parse private key"

**Root Cause:** Format private key tidak benar atau corrupt.

## ✅ SOLUSI:

### Step 1: Download Service Account Key BARU

1. Buka [Firebase Console](https://console.firebase.google.com)
2. Pilih project **Project TA** (project-ta-951b4)
3. Klik ⚙️ **Project Settings** → Tab **Service Accounts**
4. Klik **Generate New Private Key**
5. Download file JSON

### Step 2: Extract Private Key yang BENAR

Buka file JSON yang baru di-download, akan ada field `private_key`:

```json
{
  "type": "service_account",
  "project_id": "project-ta-951b4",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIB...[sangat panjang]...-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@project-ta-951b4.iam.gserviceaccount.com",
  ...
}
```

### Step 3: Copy EXACT Value

**PENTING:** Copy SELURUH value dari `private_key` field, INCLUDING:
- Opening quote `"`
- All `\n` characters (jangan hapus!)
- All key content
- Closing quote `"`

**Contoh yang BENAR:**
```env
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAA...[very long]...-----END PRIVATE KEY-----\n"
```

**JANGAN LAKUKAN INI (SALAH):**
- ❌ Menghapus `\n`
- ❌ Replace `\n` dengan newline
- ❌ Edit atau format private key
- ❌ Menambah spasi atau newline

### Step 4: Update .env File

1. Edit file `.env`:
   ```powershell
   notepad f:\ApsGo\ApsGo\railway-worker\.env
   ```

2. Replace baris `FIREBASE_PRIVATE_KEY=` dengan value BARU yang di-copy dari JSON
   - Delete seluruh baris lama
   - Paste baris baru (satu line, dengan \n tetap ada)
   - Save file

3. Test lagi:
   ```powershell
   cd f:\ApsGo\ApsGo\railway-worker
   node test-firebase-direct.js
   ```

### Alternative: Copy dari File JSON Secara Programmatic

Jika masih error, buat script helper:

```powershell
cd f:\ApsGo\ApsGo\railway-worker
node -e "const fs=require('fs'); const key=JSON.parse(fs.readFileSync('PATH_TO_YOUR_DOWNLOADED_JSON')).private_key; console.log('FIREBASE_PRIVATE_KEY=\"' + key + '\"');"
```

Copy output dan paste ke .env

---

## 🎯 Quick Checklist

- [ ] Download NEW service account key dari Firebase
- [ ] Open JSON file
- [ ] Copy EXACT value dari `private_key` field (with quotes and \n)
- [ ] Paste ke .env file (one line)
- [ ] Test: `node test-firebase-direct.js`

Expected result:
```
✅ Firebase Admin SDK initialized
✅ Successfully read /kontrol data
```