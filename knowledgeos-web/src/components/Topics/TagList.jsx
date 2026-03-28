import { useNavigate } from 'react-router-dom'

export default function TagList({ tags, counts }) {
  const navigate = useNavigate()

  const sorted = [...tags].sort((a, b) => a.name.localeCompare(b.name))

  return (
    <div className="space-y-1">
      {sorted.map((tag) => (
        <button
          key={tag.name}
          onClick={() => navigate(`/topic/${encodeURIComponent(tag.name)}`)}
          className="w-full flex items-center gap-3 px-3 py-2.5 rounded-input hover:bg-surface-hover transition-colors"
        >
          <span
            className="w-3 h-3 rounded-full shrink-0"
            style={{ backgroundColor: tag.color }}
          />
          <span className="text-sm text-text-primary flex-1 text-left">
            {tag.name}
          </span>
          <span className="text-xs text-text-tertiary">
            {counts[tag.name] || 0}
          </span>
        </button>
      ))}
    </div>
  )
}
