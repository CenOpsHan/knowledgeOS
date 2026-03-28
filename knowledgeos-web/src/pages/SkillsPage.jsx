import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useSkills } from '../hooks/useSkills'
import SkillCard from '../components/Skills/SkillCard'
import EmptyState from '../components/Shared/EmptyState'
import LoadingSpinner from '../components/Shared/LoadingSpinner'

export default function SkillsPage() {
  const navigate = useNavigate()
  const { skills, loading } = useSkills()

  if (loading) return <LoadingSpinner />

  return (
    <div>
      <h2 className="text-xl font-bold mb-4">
        Skills
        <span className="text-text-tertiary font-normal ml-2 text-base">
          {skills.length}
        </span>
      </h2>

      {skills.length === 0 ? (
        <EmptyState
          message="No skills yet. Build your first knowledge module."
          action="Create Skill"
          onAction={() => navigate('/skills/new')}
        />
      ) : (
        <div className="space-y-3">
          {skills.map((skill) => (
            <SkillCard key={skill.id} skill={skill} />
          ))}
        </div>
      )}

      <button onClick={() => navigate('/skills/new')} className="fab">
        <Plus size={24} />
      </button>
    </div>
  )
}
