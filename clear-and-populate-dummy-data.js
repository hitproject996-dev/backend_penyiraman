/**
 * Script untuk membersihkan semua history data Firebase 
 * dan mengisinya dengan dummy data (40-80) untuk testing
 * 
 * Jalankan dengan: node clear-and-populate-dummy-data.js
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
const serviceAccountPath = path.join(__dirname, 'service-account-key.json');

// Cek apakah file key ada
try {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: process.env.FIREBASE_DATABASE_URL || 'https://your-project.firebaseio.com'
  });
} catch (error) {
  console.error('❌ Service account key tidak ditemukan!');
  console.error('   Pastikan file service-account-key.json ada di railway-worker/');
  process.exit(1);
}

const db = admin.database();

// Fungsi untuk generate dummy data
function generateDummyData(startDate, endDate) {
  const data = {};
  
  let currentDate = new Date(startDate);
  
  while (currentDate <= endDate) {
    const dateKey = formatDate(currentDate);
    const dateData = {};
    
    // Generate data setiap 30 menit
    for (let hour = 0; hour < 24; hour++) {
      for (let minute = 0; minute < 60; minute += 30) {
        const timeKey = `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
        
        // Generate random values 40-80
        const soil1 = 40 + Math.random() * 40;
        const soil2 = 40 + Math.random() * 40;
        const soil3 = 40 + Math.random() * 40;
        const soil4 = 40 + Math.random() * 40;
        const soil5 = 40 + Math.random() * 40;
        
        dateData[timeKey] = {
          soil_1: soil1.toFixed(1),
          soil_2: soil2.toFixed(1),
          soil_3: soil3.toFixed(1),
          soil_4: soil4.toFixed(1),
          soil_5: soil5.toFixed(1),
          suhu: (20 + Math.random() * 15).toFixed(1),           // 20-35°C
          kelembapan: (40 + Math.random() * 40).toFixed(1),     // 40-80%
          ldr: Math.floor(300 + Math.random() * 700).toString(), // 300-1000
          source: 'dummy-data',
          timestamp: new Date(
            currentDate.getFullYear(),
            currentDate.getMonth(),
            currentDate.getDate(),
            hour,
            minute
          ).getTime().toString(),
          type: 'sensor_reading'
        };
      }
    }
    
    data[dateKey] = dateData;
    currentDate.setDate(currentDate.getDate() + 1);
  }
  
  return data;
}

// Fungsi format date
function formatDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

// Main function
async function clearAndPopulateDummyData() {
  try {
    console.log('\n🔄 Mulai proses clear dan populate dummy data...\n');
    
    // Step 1: Clear existing history data
    console.log('⏳ Step 1: Menghapus data history yang sudah ada...');
    const historyRef = db.ref('history');
    
    const snapshot = await historyRef.once('value');
    if (snapshot.exists()) {
      await historyRef.remove();
      console.log('✅ Data history berhasil dihapus!\n');
    } else {
      console.log('ℹ️  Tidak ada data history untuk dihapus\n');
    }
    
    // Step 2: Generate dummy data untuk 7 hari terakhir
    console.log('⏳ Step 2: Generate dummy data untuk 7 hari terakhir...');
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 7);
    
    const dummyData = generateDummyData(startDate, endDate);
    const totalEntries = Object.values(dummyData).reduce(
      (sum, dateData) => sum + Object.keys(dateData).length, 
      0
    );
    
    console.log(`✅ Generated ${totalEntries} data points untuk ${Object.keys(dummyData).length} hari\n`);
    
    // Step 3: Upload dummy data ke Firebase
    console.log('⏳ Step 3: Upload dummy data ke Firebase...');
    await historyRef.set(dummyData);
    console.log('✅ Dummy data berhasil diupload!\n');
    
    // Step 4: Verify data
    console.log('⏳ Step 4: Verifikasi data...');
    const verifySnapshot = await historyRef.once('value');
    const uploadedData = verifySnapshot.val();
    const uploadedEntries = Object.values(uploadedData).reduce(
      (sum, dateData) => sum + Object.keys(dateData).length,
      0
    );
    
    console.log(`✅ Verifikasi: ${uploadedEntries} data points berhasil tersimpan\n`);
    
    // Summary
    console.log('═══════════════════════════════════════════════════');
    console.log('✨ SUMMARY');
    console.log('═══════════════════════════════════════════════════');
    console.log(`📅 Periode: ${formatDate(startDate)} hingga ${formatDate(endDate)}`);
    console.log(`📊 Total data points: ${uploadedEntries}`);
    console.log(`📈 Nilai range: 40-80`);
    console.log(`🔄 Status: BERHASIL\n`);
    
    console.log('🎯 Instruksi selanjutnya:');
    console.log('1. Buka aplikasi di Flutter');
    console.log('2. Buka halaman Histori');
    console.log('3. Data dummy akan dimuat otomatis dari Firebase');
    console.log('4. Grafik harus terlihat clean tanpa outliers\n');
    
    process.exit(0);
    
  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
    console.error('\nDetail:', error);
    process.exit(1);
  }
}

// Run the script
clearAndPopulateDummyData();
