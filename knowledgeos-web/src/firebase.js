import { initializeApp } from 'firebase/app'
import { getAuth, GoogleAuthProvider } from 'firebase/auth'
import { getFirestore, enableIndexedDbPersistence } from 'firebase/firestore'
import { getStorage } from 'firebase/storage'

const firebaseConfig = {
  apiKey: 'AIzaSyDuocsxOvWJkE9iDgryLccmGEKg9gTsHGk',
  authDomain: 'knowledgeos-80279.firebaseapp.com',
  projectId: 'knowledgeos-80279',
  storageBucket: 'knowledgeos-80279.firebasestorage.app',
  messagingSenderId: '820047823170',
  appId: '1:820047823170:web:c1b7542dee9c47d3b9c8db',
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
