import { useNavigate } from 'react-router-dom'
import { Lightbulb } from 'lucide-react'
import TagPill from '../Shared/TagPill'
import { useTags } from '../../hooks/useTags'

function timeAgo(timestamp) {
  if (!timestamp) return ''
  const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp)
  const seconds = Math.floor((Date.now() - date.getTime()) / 1000)
  if (seconds < 60) return 'just now'
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`
  if (seconds < 2592000) return `${Math.floor(seconds / 86400)}d ago`
  return date.toLocaleDateString()
}

function stripMarkdown(text) {
  return (text || '')
    .replace(/#{1,6}\s/g, '')
    .replace(/\*\*(.*?)\*\*/g, '$1')
    .replace(/_(.*?)_/g, '$1')
    .replace(/`{1,3}[^`]*`{1,3}/g, '')
    .replace(/^\s*[-*]\s/gm, '')
    .replace(/^\s*\d+\.\s/gm, '')
    .replace(/\n+/g, ' ')
    .trim()
}

export default function SynthesisCard({ synthesis, bookId }) {
  const navigate = useNavigate()
  const { tags: allTags } = useTags()
  const tagColorMap = Object.fromEntries(allTags.map((t) => [t.name, t.color]))

  return (
    <div
      onClick={() => navigate(`/book/${bookId}/synthesis/${synthesis.id}`)}
      className="card cursor-pointer border-l-[3px] border-l-synthesis bg-synthesis-dim hover:bg-synthesis/[0.08] transition-colors"
    >
      <div className="flex items-start gap-2 mb-1">
        <Lightbulb size={14} className="text-synthesis mt-0.5 shrink-0" />
        <h4 className="text-sm font-semibold text-text-primary line-clamp-1">
          {synthesis.title}
        </h4>
      </div>
      <p className="text-sm text-text-secondary line-clamp-3 ml-6 mb-2">
        {stripMarkdown(synthesis.content)}
      </p>
      {synthesis.pageReferences && (
        <p className="text-xs text-text-tertiary ml-6 mb-2">
          {synthesis.pageReferences}
        </p>
      )}
      <div className="flex items-center justify-between mt-2">
        <div className="flex items-center gap-2 flex-wrap">
          {synthesis.tags?.map((tag) => (
            <TagPill key={tag} name={tag} color={tagColorMap[tag]} />
          ))}
        </div>
        <span className="text-xs text-text-tertiary shrink-0">
          {timeAgo(synthesis.dateCreated)}
        </span>
      </div>
    </div>
  )
}
