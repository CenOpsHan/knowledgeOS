import { useNavigate } from 'react-router-dom'

export default function TagCloud({ tags, counts }) {
  const navigate = useNavigate()

  const maxCount = Math.max(...Object.values(counts), 1)

  return (
    <div className="flex flex-wrap gap-3 justify-center py-4">
      {tags.map((tag) => {
        const count = counts[tag.name] || 0
        const fontSize = Math.max(12, Math.min(28, 12 + (count / maxCount) * 16))
        return (
          <button
            key={tag.name}
            onClick={() => navigate(`/topic/${encodeURIComponent(tag.name)}`)}
            className="px-3 py-1.5 rounded-pill transition-transform hover:scale-110"
            style={{
              fontSize: `${fontSize}px`,
              backgroundColor: `${tag.color}26`,
              color: tag.color,
            }}
          >
            {tag.name}
          </button>
        )
      })}
    </div>
  )
}
