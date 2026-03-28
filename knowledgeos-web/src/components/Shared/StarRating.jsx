import { Star } from 'lucide-react'

export default function StarRating({ rating, onChange, size = 18 }) {
  return (
    <div className="flex gap-0.5">
      {[1, 2, 3, 4, 5].map((i) => (
        <button
          key={i}
          onClick={() => onChange?.(rating === i ? null : i)}
          disabled={!onChange}
          className="disabled:cursor-default"
        >
          <Star
            size={size}
            className={
              i <= (rating || 0)
                ? 'fill-star text-star'
                : 'text-text-tertiary'
            }
          />
        </button>
      ))}
    </div>
  )
}
