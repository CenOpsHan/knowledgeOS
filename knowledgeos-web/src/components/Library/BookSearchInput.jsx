import { useState, useEffect, useRef } from 'react'
import { Search, Loader2 } from 'lucide-react'
import { searchBooks } from '../../services/googleBooks'

export default function BookSearchInput({ onSelect }) {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState([])
  const [loading, setLoading] = useState(false)
  const [showResults, setShowResults] = useState(false)
  const timerRef = useRef(null)

  useEffect(() => {
    if (timerRef.current) clearTimeout(timerRef.current)
    if (query.length < 3) {
      setResults([])
      return
    }
    setLoading(true)
    timerRef.current = setTimeout(async () => {
      try {
        const data = await searchBooks(query)
        setResults(data)
        setShowResults(true)
      } catch {
        setResults([])
      } finally {
        setLoading(false)
      }
    }, 400)
    return () => clearTimeout(timerRef.current)
  }, [query])

  return (
    <div className="relative">
      <div className="relative">
        <Search
          size={18}
          className="absolute left-3 top-1/2 -translate-y-1/2 text-text-tertiary"
        />
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onFocus={() => results.length > 0 && setShowResults(true)}
          onBlur={() => setTimeout(() => setShowResults(false), 200)}
          placeholder="Search by title, author, or ISBN..."
          className="w-full pl-10 pr-10 text-base"
        />
        {loading && (
          <Loader2
            size={18}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-text-tertiary animate-spin"
          />
        )}
      </div>

      {showResults && results.length > 0 && (
        <div className="absolute z-20 top-full left-0 right-0 mt-1 bg-surface-elevated border border-border rounded-card max-h-80 overflow-y-auto">
          {results.map((book) => (
            <button
              key={book.googleBooksId}
              onMouseDown={() => {
                onSelect(book)
                setQuery('')
                setResults([])
                setShowResults(false)
              }}
              className="w-full text-left px-4 py-3 hover:bg-surface-hover flex items-center gap-3 border-b border-border last:border-0"
            >
              <div className="w-10 h-15 rounded bg-surface flex-shrink-0 overflow-hidden">
                {book.coverUrl ? (
                  <img
                    src={book.coverUrl}
                    alt=""
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full bg-surface-hover" />
                )}
              </div>
              <div className="min-w-0">
                <p className="text-sm font-medium text-text-primary truncate">
                  {book.title}
                </p>
                <p className="text-xs text-text-secondary truncate">
                  {book.authors?.join(', ')}
                  {book.publishedDate && ` · ${book.publishedDate.substring(0, 4)}`}
                </p>
              </div>
            </button>
          ))}
          <button
            onMouseDown={() => {
              onSelect(null)
              setShowResults(false)
            }}
            className="w-full text-center px-4 py-3 text-sm text-accent hover:bg-surface-hover"
          >
            Can't find it? Add manually
          </button>
        </div>
      )}
    </div>
  )
}
