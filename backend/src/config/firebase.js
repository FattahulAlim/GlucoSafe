const { initializeApp, getApps, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const fs = require('fs');
const path = require('path');

const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');

let firebaseInitialized = false;

if (fs.existsSync(serviceAccountPath)) {
  if (!getApps().length) {
    initializeApp({
      credential: cert(require(serviceAccountPath)),
    });
  }
  firebaseInitialized = true;
} else {
  console.warn(
    '[FCM] firebase-service-account.json tidak ditemukan di backend/. Notifikasi push dinonaktifkan sampai file ditambahkan.'
  );
}

module.exports = { getMessaging, firebaseInitialized };
