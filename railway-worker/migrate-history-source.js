require('dotenv').config();
const admin = require('firebase-admin');

function inferSource(entry) {
  const rawSource = (entry && entry.source ? String(entry.source) : '').trim().toLowerCase();

  if (rawSource === 'server' || rawSource === 'worker') return 'server';
  if (rawSource === 'app' || rawSource === 'mobile') return 'app';

  const rawType = (entry && entry.type ? String(entry.type) : '').trim();
  if (rawType.length > 0) return 'server';

  return 'app';
}

async function main() {
  const isDryRun = process.argv.includes('--dry-run');

  const requiredEnvs = [
    'FIREBASE_PROJECT_ID',
    'FIREBASE_CLIENT_EMAIL',
    'FIREBASE_PRIVATE_KEY',
    'FIREBASE_DATABASE_URL',
  ];

  const missing = requiredEnvs.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(`Missing env vars: ${missing.join(', ')}`);
  }

  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    }),
    databaseURL: process.env.FIREBASE_DATABASE_URL,
  });

  const db = admin.database();
  const snap = await db.ref('history').get();

  if (!snap.exists()) {
    console.log('No history node found. Nothing to migrate.');
    await admin.app().delete();
    return;
  }

  const history = snap.val();
  const updates = {};

  let totalEntries = 0;
  let changedEntries = 0;
  let serverAssigned = 0;
  let appAssigned = 0;

  for (const dateKey of Object.keys(history)) {
    const dateNode = history[dateKey];
    if (!dateNode || typeof dateNode !== 'object') continue;

    for (const timeKey of Object.keys(dateNode)) {
      const entry = dateNode[timeKey];
      if (!entry || typeof entry !== 'object') continue;

      totalEntries += 1;
      const target = inferSource(entry);
      const currentRaw = entry.source == null ? '' : String(entry.source).trim().toLowerCase();
      const current = currentRaw === 'worker' ? 'server' : currentRaw === 'mobile' ? 'app' : currentRaw;

      if (current !== target) {
        updates[`history/${dateKey}/${timeKey}/source`] = target;
        changedEntries += 1;
        if (target === 'server') {
          serverAssigned += 1;
        } else {
          appAssigned += 1;
        }
      }
    }
  }

  console.log('=== History Source Migration ===');
  console.log(`Mode: ${isDryRun ? 'DRY RUN' : 'APPLY'}`);
  console.log(`Total entries scanned: ${totalEntries}`);
  console.log(`Entries to update: ${changedEntries}`);
  console.log(`Assign source=server: ${serverAssigned}`);
  console.log(`Assign source=app: ${appAssigned}`);

  if (!isDryRun && changedEntries > 0) {
    await db.ref().update(updates);
    console.log('Migration applied successfully.');
  } else if (!isDryRun) {
    console.log('No updates needed.');
  }

  await admin.app().delete();
}

main().catch(async (err) => {
  console.error('Migration failed:', err.message);
  process.exitCode = 1;
  try {
    await admin.app().delete();
  } catch (_) {}
});
