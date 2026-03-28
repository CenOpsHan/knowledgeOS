import { initializeApp } from 'firebase/app'
import { getAuth, GoogleAuthProvider } from 'firebase/auth'
import { getFirestore, enableIndexedDbPersistence } from 'firebase/firestore'
import { getStorage } from 'firebase/storage'

// TODO: Replace with your Firebase project config from Firebase Console
const firebaseConfig = {
  apiKey: 'YOUR_API_KEY',
  authDomain: 'knowledgeos.firebaseapp.com',
  projectId: 'knowledgeos',
  storageBucket: 'knowledgeos.firebasestorage.app',
  messagingSenderId: 'YOUR_SENDER_ID',
  appId: 'YOUR_APP_ID',
}

const app = initializeApp(firebaseConfig)
export const auth = getAuth(app)
export const googleProvider = new GoogleAuthProvider()
export const db = getFirestore(app)
export const storage = getStorage(app)

enableIndexedDbPersistence(db).catch((err) => {
  if (err.code === 'failed-precondition') {
    console.warn('Firestore persistence failed: multiple tabs open')
  } else if (err.code === 'unimplemented') {
    console.warn('Firestore persistence not available in this browser')
  }
})
