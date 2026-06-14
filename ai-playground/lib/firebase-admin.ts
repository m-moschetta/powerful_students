import admin from 'firebase-admin';

let initialized = false;

export function isFirebaseAdminConfigured(): boolean {
  return Boolean(process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim());
}

export function getFirestoreAdmin() {
  if (!isFirebaseAdminConfigured()) {
    return null;
  }
  if (!initialized) {
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON!.trim();
    const serviceAccount = JSON.parse(raw) as admin.ServiceAccount;
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    initialized = true;
  }
  return admin.firestore();
}
