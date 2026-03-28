import { useState, useEffect } from 'react'
import { useAuth } from './useAuth'
import { subscribeBooks } from '../services/firestore'

export function useBooks() {
  const { user } = useAuth()
  const [books, setBooks] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!user) return
    const unsub = subscribeBooks(user.uid, (data) => {
      setBooks(data)
      setLoading(false)
    })
    return unsub
  }, [user])

  return { books, loading }
}
