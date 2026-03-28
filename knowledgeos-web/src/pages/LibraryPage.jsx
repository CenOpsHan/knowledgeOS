import { useState, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useBooks } from '../hooks/useBooks'
import BookCard from '../components/Library/BookCard'
import EmptyState from '../components/Shared/EmptyState'
import LoadingSpinner from '../components/Shared/LoadingSpinner'

const STATUS_FILTERS = ['all', 'reading', 'completed', 'shelved']
const SORT_OPTIONS = [
  { value: 'recent', label: 'Recent' },
  { value: 'az', label: 'A-Z' },
  { value: 'rating', label: 'Rating' },
]

export default function LibraryPage() {
  const navigate = useNavigate()
  const { books, loading } = useBooks()
  const [statusFilter, setStatusFilter] = useState('all')
  const [sort, setSort] = useState('recent')

  const filtered = useMemo(() => {
    let result = statusFilter === 'all'
      ? books
      : books.filter((b) => b.status === statusFilter)

    switch (sort) {
      case 'az':
        result = [...result].sort((a, b) => (a.title || '').localeCompare(b.title || ''))
        break
      case 'rating':
        result = [...result].sort((a, b) => (b.rating || 0) - (a.rating || 0))
        break
      default:
        break // already sorted by dateAdded desc from Firestore
    }

    return result
  }, [books, statusFilter, sort])

  if (loading) return <LoadingSpinner />

  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-bold">
          Library
          <span className="text-text-tertiary font-normal ml-2 text-base">
            {books.length} books
          </span>
        </h2>
        <select
          value={sort}
          onChange={(e) => setSort(e.target.value)}
          className="text-sm bg-surface-elevated"
        >
          {SORT_OPTIONS.map((o) => (
            <option key={o.value} value={o.value}>{o.label}</option>
          ))}
        </select>
      </div>

      <div className="flex gap-2 mb-6 overflow-x-auto pb-1">
        {STATUS_FILTERS.map((s) => (
          <button
            key={s}
            onClick={() => setStatusFilter(s)}
            className={`pill text-sm whitespace-nowrap ${
              statusFilter === s
                ? 'bg-accent text-white'
                : 'bg-surface-elevated text-text-secondary border border-border'
            }`}
          >
            {s.charAt(0).toUpperCase() + s.slice(1)}
          </button>
        ))}
      </div>

      {filtered.length === 0 ? (
        <EmptyState
          message="Your library is empty"
          action="Add your first book"
          onAction={() => navigate('/add-book')}
        />
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-card-gap">
          {filtered.map((book) => (
            <BookCard key={book.id} book={book} />
          ))}
        </div>
      )}

      <button onClick={() => navigate('/add-book')} className="fab">
        <Plus size={24} />
      </button>
    </div>
  )
}
