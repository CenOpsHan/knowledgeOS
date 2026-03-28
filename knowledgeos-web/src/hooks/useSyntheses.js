import { useState, useEffect } from 'react'
import { useAuth } from './useAuth'
import { subscribeSyntheses, subscribeAllSyntheses } from '../services/firestore'

export function useSyntheses(bookId) {
  const { user } = useAuth()
  const [syntheses, setSyntheses] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!user) return
    const unsub = bookId
      ? subscribeSyntheses(user.uid, bookId, (data) => {
          setSyntheses(data)
          setLoading(false)
        })
      : subscribeAllSyntheses(user.uid, (data) => {
          setSyntheses(data)
          setLoading(false)
        })
    return unsub
  }, [user, bookId])

  return { syntheses, loading }
}
