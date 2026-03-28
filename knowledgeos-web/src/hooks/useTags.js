import { useState, useEffect } from 'react'
import { useAuth } from './useAuth'
import { subscribeTags } from '../services/firestore'

export function useTags() {
  const { user } = useAuth()
  const [tags, setTags] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!user) return
    const unsub = subscribeTags(user.uid, (data) => {
      setTags(data)
      setLoading(false)
    })
    return unsub
  }, [user])

  return { tags, loading }
}
