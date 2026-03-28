import { useNavigate } from 'react-router-dom'
import { Quote } from 'lucide-react'
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

export default function ExtractCard({ extract, bookId }) {
  const navigate = useNavigate()
  const { tags: allTags } = useTags()
  const tagColorMap = Object.fromEntries(allTags.map((t) => [t.name, t.color]))

  const pageLabel = extract.pageRange
    ? `pp. ${extract.pageRange}`
    : extract.pageNumber
    ? `p. ${extract.pageNumber}`
    : null

  return (
    <div
      onClick={() => navigate(`/book/${bookId}/extract/${extract.id}`)}
      className="card cursor-pointer border-l-[3px] border-l-extract bg-extract-dim hover:bg-extract/[0.08] transition-colors"
    >
      <div className="flex items-start gap-2 mb-2">
        <Quote size={14} className="text-extract mt-0.5 shrink-0" />
        <p className="font-mono text-sm text-text-primary line-clamp-3">
          {extract.content}
        </p>
      </div>
      <div className="flex items-center justify-between mt-3">
        <div className="flex items-center gap-2 flex-wrap">
          {pageLabel && (
            <span className="pill bg-surface-elevated text-text-secondary text-xs">
              {pageLabel}
            </span>
          )}
          {extract.tags?.map((tag) => (
            <TagPill key={tag} name={tag} color={tagColorMap[tag]} />
          ))}
        </div>
        <span className="text-xs text-text-tertiary shrink-0">
          {timeAgo(extract.dateCreated)}
        </span>
      </div>
    </div>
  )
}
