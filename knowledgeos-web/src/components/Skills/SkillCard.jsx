import { useNavigate } from 'react-router-dom'

function timeAgo(timestamp) {
  if (!timestamp) return ''
  const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp)
  const seconds = Math.floor((Date.now() - date.getTime()) / 1000)
  if (seconds < 86400) return 'today'
  if (seconds < 2592000) return `${Math.floor(seconds / 86400)}d ago`
  return date.toLocaleDateString()
}

export default function SkillCard({ skill }) {
  const navigate = useNavigate()

  const totalLinked = (skill.sections || []).reduce(
    (sum, s) =>
      sum + (s.linkedExtractIds?.length || 0) + (s.linkedSynthesisIds?.length || 0),
    0
  )

  return (
    <div
      onClick={() => navigate(`/skill/${skill.id}`)}
      className="card cursor-pointer hover:-translate-y-1 hover:shadow-lg transition-all"
    >
      <div className="flex items-start gap-3">
        <span className="text-3xl">{skill.icon || '📚'}</span>
        <div className="min-w-0 flex-1">
          <h3 className="text-base font-semibold text-text-primary truncate">
            {skill.name}
          </h3>
          <p className="text-sm text-text-secondary line-clamp-2 mt-1">
            {skill.description}
          </p>
          <p className="text-xs text-text-tertiary mt-2">
            {skill.sections?.length || 0} sections · {totalLinked} linked items
            {skill.dateModified && ` · Modified ${timeAgo(skill.dateModified)}`}
          </p>
        </div>
      </div>
    </div>
  )
}
