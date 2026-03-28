import { ref, getDownloadURL } from 'firebase/storage'
import { storage } from '../firebase'

export async function getPhotoURL(path) {
  try {
    return await getDownloadURL(ref(storage, path))
  } catch {
    return null
  }
}

export async function getPhotoURLs(paths) {
  const urls = await Promise.all(paths.map(getPhotoURL))
  return urls.filter(Boolean)
}
