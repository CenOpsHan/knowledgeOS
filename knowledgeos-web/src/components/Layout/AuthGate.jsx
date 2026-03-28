import { useAuth } from '../../hooks/useAuth'
import LoginPage from '../../pages/LoginPage'

export default function AuthGate({ children }) {
  const { user, loading } = useAuth()

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="w-8 h-8 border-2 border-accent border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }

  if (!user) return <LoginPage />

  return children
}
