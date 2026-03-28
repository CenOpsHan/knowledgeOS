import { signInWithPopup, signOut as firebaseSignOut, onAuthStateChanged } from 'firebase/auth'
import { auth, googleProvider } from '../firebase'

export function signInWithGoogle() {
  return signInWithPopup(auth, googleProvider)
}

export function signOut() {
  return firebaseSignOut(auth)
}

export function onAuthChange(callback) {
  return onAuthStateChanged(auth, callback)
}
