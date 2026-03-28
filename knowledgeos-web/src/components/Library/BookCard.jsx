import { useNavigate } from 'react-router-dom'
import { Star } from 'lucide-react'

export default function BookCard({ book }) {
  const navigate = useNavigate()

  return (
    <div
      onClick={() => navigate(`/book/${book.id}`)}
      className="card cursor-pointer hover:-translate-y-1 hover:shadow-lg transition-all group"
    >
      <div className="aspect-[2/3] rounded-lg overflow-hidden mb-3 bg-surface-elevated">
        {book.coverUrl ? (
          <img
            src={book.coverUrl}
            alt={book.title}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-accent/20 to-skill/20">
            <span className="text-4xl font-bold text-text-primary/60">
              {book.title?.[0] || '?'}
            </span>
          </div>
        )}
      </div>
      <h3 className="text-sm font-semibold text-text-primary line-clamp-2 mb-1">
        {book.title}
      </h3>
      <p className="text-xs text-text-secondary line-clamp-1 mb-2">
        {book.authors?.join(', ') || 'Unknown author'}
      </p>
      <div className="flex items-center justify-between">
        {book.verbatimCount > 0 && (
          <span className="text-xs text-text-tertiary">
            {book.verbatimCount}
          </span>
        )}
        {book.rating && (
          <div className="flex items-center gap-0.5">
            <Star size={12} className="fill-star text-star" />
            <span className="text-xs text-text-tertiary">{book.rating}</span>
          </div>
        )}
      </div>
    </div>
  )
}
