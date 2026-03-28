import { useState, useEffect } from 'react'
import { useAuth } from './useAuth'
import { subscribeExtracts, subscribeAllExtracts } from '../services/firestore'

export function useExtracts(bookId) {
  const { user } = useAuth()
  const [extracts, setExtracts] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!user) return
    const unsub = bookId
      ? subscribeExtracts(user.uid, bookId, (data) => {
          setExtracts(data)
          setLoading(false)
        })
      : subscribeAllExtracts(user.uid, (data) => {
          setExtracts(data)
          setLoading(false)
        })
    return unsub
  }, [user, bookId])

  return { extracts, loading }
}
