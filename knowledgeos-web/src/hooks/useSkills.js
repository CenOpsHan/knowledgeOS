import { useState, useEffect } from 'react'
import { useAuth } from './useAuth'
import { subscribeSkills } from '../services/firestore'

export function useSkills() {
  const { user } = useAuth()
  const [skills, setSkills] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!user) return
    const unsub = subscribeSkills(user.uid, (data) => {
      setSkills(data)
      setLoading(false)
    })
    return unsub
  }, [user])

  return { skills, loading }
}
