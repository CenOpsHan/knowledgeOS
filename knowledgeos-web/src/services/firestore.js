import {
  collection,
  doc,
  addDoc,
  setDoc,
  updateDoc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
  onSnapshot,
  writeBatch,
  increment,
  serverTimestamp,
} from 'firebase/firestore'
import { db } from '../firebase'

function userCol(userId, colName) {
  return collection(db, 'users', userId, colName)
}

function userDoc(userId, colName, docId) {
  return doc(db, 'users', userId, colName, docId)
}

// Commit operations in chunks of 499 to stay under Firestore's 500-op batch limit
async function commitInChunks(ops) {
  const CHUNK_SIZE = 499
  for (let i = 0; i < ops.length; i += CHUNK_SIZE) {
    const chunk = ops.slice(i, i + CHUNK_SIZE)
    const batch = writeBatch(db)
    for (const op of chunk) {
      if (op.type === 'delete') batch.delete(op.ref)
      else if (op.type === 'set') batch.set(op.ref, op.data)
      else if (op.type === 'update') batch.update(op.ref, op.data)
    }
    await batch.commit()
  }
}

// ─── Books ───

export function subscribeBooks(userId, callback) {
  const q = query(userCol(userId, 'books'), orderBy('dateAdded', 'desc'))
  return onSnapshot(q, (snap) => {
    callback(snap.docs.map((d) => ({ id: d.id, ...d.data() })))
  })
}

export async function createBook(userId, bookData) {
  const ref = await addDoc(userCol(userId, 'books'), {
    ...bookData,
    verbatimCount: 0,
    synthesisCount: 0,
    status: bookData.status || 'reading',
    rating: null,
    personalNote: null,
    dateAdded: serverTimestamp(),
    dateModified: serverTimestamp(),
  })
  return ref.id
}

export async function updateBook(userId, bookId, data) {
  await updateDoc(userDoc(userId, 'books', bookId), {
    ...data,
    dateModified: serverTimestamp(),
  })
}

export async function deleteBook(userId, bookId) {
  const ops = [{ type: 'delete', ref: userDoc(userId, 'books', bookId) }]

  const extractsSnap = await getDocs(
    query(userCol(userId, 'extracts'), where('bookId', '==', bookId))
  )
  extractsSnap.docs.forEach((d) => ops.push({ type: 'delete', ref: d.ref }))

  const synthesesSnap = await getDocs(
    query(userCol(userId, 'syntheses'), where('bookId', '==', bookId))
  )
  synthesesSnap.docs.forEach((d) => ops.push({ type: 'delete', ref: d.ref }))

  await commitInChunks(ops)
}

// ─── Extracts ───

export function subscribeExtracts(userId, bookId, callback) {
  const q = query(
    userCol(userId, 'extracts'),
    where('bookId', '==', bookId),
    orderBy('dateCreated', 'desc')
  )
  return onSnapshot(q, (snap) => {
    callback(snap.docs.map((d) => ({ id: d.id, ...d.data() })))
  })
}

export function subscribeAllExtracts(userId, callback) {
  const q = query(userCol(userId, 'extracts'), orderBy('dateCreated', 'desc'))
  return onSnapshot(q, (snap) => {
    callback(snap.docs.map((d) => ({ id: d.id, ...d.data() })))
  })
}

export async function getExtract(userId, extractId) {
  const snap = await getDoc(userDoc(userId, 'extracts', extractId))
  return snap.exists() ? { id: snap.id, ...snap.data() } : null
}

export async function updateExtract(userId, extractId, data) {
  await updateDoc(userDoc(userId, 'extracts', extractId), {
    ...data,
    dateModified: serverTimestamp(),
  })
}

export async function deleteExtract(userId, extractId, bookId) {
  const batch = writeBatch(db)
  batch.delete(userDoc(userId, 'extracts', extractId))
  batch.update(userDoc(userId, 'books', bookId), {
    verbatimCount: increment(-1),
    dateModified: serverTimestamp(),
  })
  await batch.commit()
}

// ─── Syntheses ───

export function subscribeSyntheses(userId, bookId, callback) {
  const q = query(
    userCol(userId, 'syntheses'),
    where('bookId', '==', bookId),
    orderBy('dateCreated', 'desc')
  )
  return onSnapshot(q, (snap) => {
    callback(snap.docs.map((d) => ({ id: d.id, ...d.data() })))
  })
}

export function subscribeAllSyntheses(userId, callback) {
  const q = query(userCol(userId, 'syntheses'), orderBy('dateCreated', 'desc'))
  return onSnapshot(q, (snap) => {
    callback(snap.docs.map((d) => ({ id: d.id, ...d.data() })))
  })
}

export async function createSynthesis(userId, data) {
  const batch = writeBatch(db)
  const ref = doc(userCol(userId, 'syntheses'))
  batch.set(ref, {
    ...data,
    tags: data.tags || [],
    linkedSkillIds: [],
    dateCreated: serverTimestamp(),
    dateModified: serverTimestamp(),
  })
  batch.update(userDoc(userId, 'books', data.bookId), {
    synthesisCount: increment(1),
    dateModified: serverTimestamp(),
  })
  await batch.commit()
  return ref.id
}

export async function getSynthesis(userId, synthesisId) {
  const snap = await getDoc(userDoc(userId, 'syntheses', synthesisId))
  return snap.exists() ? { id: snap.id, ...snap.data() } : null
}

export async function updateSynthesis(userId, synthesisId, data) {
  await updateDoc(userDoc(userId, 'syntheses', synthesisId), {
    ...data,
    dateModified: serverTimestamp(),
  })
}

export async function deleteSynthesis(userId, synthesisId, bookId) {
  const batch = writeBatch(db)
  batch.delete(userDoc(userId, 'syntheses', synthesisId))
  batch.update(userDoc(userId, 'books', bookId), {
    synthesisCount: increment(-1),
    dateModified: serverTimestamp(),
  })
  await batch.commit()
}

// ─── Skills ───

export function subscribeSkills(userId, callback) {
  const q = query(userCol(userId, 'skills'), orderBy('dateCreated', 'desc'))
  return onSnapshot(q, (snap) => {
    callback(snap.docs.map((d) => ({ id: d.id, ...d.data() })))
  })
}

export async function getSkill(userId, skillId) {
  const snap = await getDoc(userDoc(userId, 'skills', skillId))
  return snap.exists() ? { id: snap.id, ...snap.data() } : null
}

export async function createSkill(userId, data) {
  const ref = await addDoc(userCol(userId, 'skills'), {
    ...data,
    dateCreated: serverTimestamp(),
    dateModified: serverTimestamp(),
  })
  return ref.id
}

export async function updateSkill(userId, skillId, data) {
  await updateDoc(userDoc(userId, 'skills', skillId), {
    ...data,
    dateModified: serverTimestamp(),
  })
}

export async function deleteSkill(userId, skillId) {
  const skillSnap = await getDoc(userDoc(userId, 'skills', skillId))
  if (!skillSnap.exists()) return

  const skill = skillSnap.data()
  const ops = [{ type: 'delete', ref: userDoc(userId, 'skills', skillId) }]

  const linkedIds = new Set()
  for (const section of skill.sections || []) {
    ;(section.linkedExtractIds || []).forEach((id) => linkedIds.add(`extract:${id}`))
    ;(section.linkedSynthesisIds || []).forEach((id) => linkedIds.add(`synthesis:${id}`))
  }

  for (const key of linkedIds) {
    const [type, id] = key.split(':')
    const colName = type === 'extract' ? 'extracts' : 'syntheses'
    const docSnap = await getDoc(userDoc(userId, colName, id))
    if (docSnap.exists()) {
      const current = docSnap.data().linkedSkillIds || []
      ops.push({ type: 'update', ref: docSnap.ref, data: { linkedSkillIds: current.filter((sid) => sid !== skillId) } })
    }
  }

  await commitInChunks(ops)
}

export async function linkKnowledgeToSkill(userId, skillId, sectionId, extractIds, synthesisIds) {
  const skillSnap = await getDoc(userDoc(userId, 'skills', skillId))
  if (!skillSnap.exists()) return

  const skill = skillSnap.data()
  const batch = writeBatch(db)

  const sections = skill.sections.map((s) => {
    if (s.id !== sectionId) return s
    return {
      ...s,
      linkedExtractIds: [...new Set([...(s.linkedExtractIds || []), ...extractIds])],
      linkedSynthesisIds: [...new Set([...(s.linkedSynthesisIds || []), ...synthesisIds])],
    }
  })

  batch.update(userDoc(userId, 'skills', skillId), {
    sections,
    dateModified: serverTimestamp(),
  })

  for (const id of extractIds) {
    const d = await getDoc(userDoc(userId, 'extracts', id))
    if (d.exists()) {
      const current = d.data().linkedSkillIds || []
      if (!current.includes(skillId)) {
        batch.update(d.ref, { linkedSkillIds: [...current, skillId] })
      }
    }
  }

  for (const id of synthesisIds) {
    const d = await getDoc(userDoc(userId, 'syntheses', id))
    if (d.exists()) {
      const current = d.data().linkedSkillIds || []
      if (!current.includes(skillId)) {
        batch.update(d.ref, { linkedSkillIds: [...current, skillId] })
      }
    }
  }

  await batch.commit()
}

export async function unlinkKnowledgeFromSkill(userId, skillId, sectionId, itemType, itemId) {
  const skillSnap = await getDoc(userDoc(userId, 'skills', skillId))
  if (!skillSnap.exists()) return

  const skill = skillSnap.data()
  const batch = writeBatch(db)

  const sections = skill.sections.map((s) => {
    if (s.id !== sectionId) return s
    if (itemType === 'extract') {
      return { ...s, linkedExtractIds: (s.linkedExtractIds || []).filter((id) => id !== itemId) }
    }
    return { ...s, linkedSynthesisIds: (s.linkedSynthesisIds || []).filter((id) => id !== itemId) }
  })

  batch.update(userDoc(userId, 'skills', skillId), { sections, dateModified: serverTimestamp() })

  const colName = itemType === 'extract' ? 'extracts' : 'syntheses'
  const d = await getDoc(userDoc(userId, colName, itemId))
  if (d.exists()) {
    // Only remove skill link if this item is no longer in any section of this skill
    const stillLinked = sections.some((s) => {
      const ids = itemType === 'extract' ? s.linkedExtractIds : s.linkedSynthesisIds
      return (ids || []).includes(itemId)
    })
    if (!stillLinked) {
      const current = d.data().linkedSkillIds || []
      batch.update(d.ref, { linkedSkillIds: current.filter((sid) => sid !== skillId) })
    }
  }

  await batch.commit()
}

// ─── Tags ───

export function subscribeTags(userId, callback) {
  return onSnapshot(userCol(userId, 'tags'), (snap) => {
    callback(snap.docs.map((d) => ({ name: d.id, ...d.data() })))
  })
}

export async function createTag(userId, name, color) {
  const tagDoc = doc(db, 'users', userId, 'tags', name.toLowerCase())
  await setDoc(tagDoc, { color, dateCreated: serverTimestamp() })
}

export async function updateTag(userId, oldName, newName, color) {
  if (oldName !== newName) {
    // Collect all operations
    const ops = []
    ops.push({ type: 'delete', ref: doc(db, 'users', userId, 'tags', oldName) })
    ops.push({ type: 'set', ref: doc(db, 'users', userId, 'tags', newName), data: { color, dateCreated: serverTimestamp() } })

    const extractsSnap = await getDocs(
      query(userCol(userId, 'extracts'), where('tags', 'array-contains', oldName))
    )
    extractsSnap.docs.forEach((d) => {
      const tags = d.data().tags.map((t) => (t === oldName ? newName : t))
      ops.push({ type: 'update', ref: d.ref, data: { tags } })
    })

    const synthesesSnap = await getDocs(
      query(userCol(userId, 'syntheses'), where('tags', 'array-contains', oldName))
    )
    synthesesSnap.docs.forEach((d) => {
      const tags = d.data().tags.map((t) => (t === oldName ? newName : t))
      ops.push({ type: 'update', ref: d.ref, data: { tags } })
    })

    await commitInChunks(ops)
  } else {
    await updateDoc(doc(db, 'users', userId, 'tags', oldName), { color })
  }
}

export async function deleteTag(userId, tagName) {
  const ops = [{ type: 'delete', ref: doc(db, 'users', userId, 'tags', tagName) }]

  const extractsSnap = await getDocs(
    query(userCol(userId, 'extracts'), where('tags', 'array-contains', tagName))
  )
  extractsSnap.docs.forEach((d) => {
    ops.push({ type: 'update', ref: d.ref, data: { tags: d.data().tags.filter((t) => t !== tagName) } })
  })

  const synthesesSnap = await getDocs(
    query(userCol(userId, 'syntheses'), where('tags', 'array-contains', tagName))
  )
  synthesesSnap.docs.forEach((d) => {
    ops.push({ type: 'update', ref: d.ref, data: { tags: d.data().tags.filter((t) => t !== tagName) } })
  })

  await commitInChunks(ops)
}
