import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, MoreHorizontal, Plus, BookOpen, Lightbulb, Tag } from 'lucide-react'
import { useAuth } from '../hooks/useAuth'
import { useBooks } from '../hooks/useBooks'
import { useExtracts } from '../hooks/useExtracts'
import { useSyntheses } from '../hooks/useSyntheses'
import { useTags } from '../hooks/useTags'
import { updateBook, deleteBook } from '../services/firestore'
import StarRating from '../components/Shared/StarRating'
import ExtractCard from '../components/Library/ExtractCard'
import SynthesisCard from '../components/Library/SynthesisCard'
import EmptyState from '../components/Shared/EmptyState'
import ConfirmDialog from '../components/Shared/ConfirmDialog'
import LoadingSpinner from '../components/Shared/LoadingSpinner'

export default function BookDetailPage() {
  const { bookId } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const { books, loading: booksLoading } = useBooks()
  const { extracts, loading: extractsLoading } = useExtracts(bookId)
  const { syntheses, loading: synthesesLoading } = useSyntheses(bookId)
  const { tags: allTags } = useTags()

  const [tab, setTab] = useState('extracts')
  const [showMenu, setShowMenu] = useState(false)
  const [showDelete, setShowDelete] = useState(false)
  const [noteExpanded, setNoteExpanded] = useState(false)
  const [note, setNote] = useState('')

  const book = books.find((b) => b.id === bookId)

  useEffect(() => {
    if (book?.personalNote !== undefined) setNote(book.personalNote || '')
  }, [book?.personalNote])

  if (booksLoading) return <LoadingSpinner />
  if (!book) return <EmptyState message="Book not found" />

  const handleNoteBlur = () => {
    if (user && note !== (book.personalNote || '')) {
      updateBook(user.uid, bookId, { personalNote: note })
    }
  }

  const handleDelete = async () => {
    if (!user) return
    await deleteBook(user.uid, bookId)
    navigate('/')
  }

  const handleRating = (rating) => {
    if (user) updateBook(user.uid, bookId, { rating })
  }

  const handleStatusChange = (status) => {
    if (user) updateBook(user.uid, bookId, { status })
  }

  const uniqueTags = new Set([
    ...extracts.flatMap((e) => e.tags || []),
    ...syntheses.flatMap((s) => s.tags || []),
  ])

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <button onClick={() => navigate('/')} className="flex items-center gap-1 text-text-secondary hover:text-text-primary">
          <ArrowLeft size={20} /> Back
        </button>
        <div className="relative">
          <button onClick={() => setShowMenu(!showMenu)} className="p-2 text-text-secondary hover:text-text-primary">
            <MoreHorizontal size={20} />
          </button>
          {showMenu && (
            <div className="absolute right-0 top-full mt-1 bg-surface-elevated border border-border rounded-card py-1 min-w-[160px] z-20">
              <button
                onClick={() => { setShowMenu(false); setShowDelete(true) }}
                className="w-full text-left px-4 py-2 text-sm text-destructive hover:bg-surface-hover"
              >
                Delete Book
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Hero */}
      <div className="text-center mb-8">
        <div className="w-28 h-auto mx-auto mb-4 rounded-lg overflow-hidden shadow-lg">
          {book.coverUrl ? (
            <img src={book.coverUrl} alt={book.title} className="w-full" />
          ) : (
            <div className="w-28 h-40 bg-gradient-to-br from-accent/20 to-skill/20 flex items-center justify-center">
              <span className="text-3xl font-bold text-text-primary/60">{book.title?.[0]}</span>
            </div>
          )}
        </div>
        <h1 className="text-2xl font-bold mb-1">{book.title}</h1>
        <p className="text-text-secondary mb-2">{book.authors?.join(', ')}</p>
        <p className="text-sm text-text-tertiary mb-3">
          {[book.publisher, book.publishedDate?.substring(0, 4), book.pageCount && `${book.pageCount} pages`]
            .filter(Boolean)
            .join(' · ')}
        </p>

        <div className="flex items-center justify-center gap-3 mb-3">
          <select
            value={book.status}
            onChange={(e) => handleStatusChange(e.target.value)}
            className="text-sm bg-surface-elevated"
          >
            <option value="reading">Reading</option>
            <option value="completed">Completed</option>
            <option value="shelved">Shelved</option>
          </select>
        </div>

        <div className="flex justify-center">
          <StarRating rating={book.rating} onChange={handleRating} size={22} />
        </div>
      </div>

      {/* Personal Note */}
      <div className="card mb-6">
        <button
          onClick={() => setNoteExpanded(!noteExpanded)}
          className="flex items-center justify-between w-full text-left"
        >
          <span className="text-sm font-semibold text-text-secondary">Personal Note</span>
          <span className="text-text-tertiary">{noteExpanded ? '−' : '+'}</span>
        </button>
        {noteExpanded && (
          <textarea
            value={note}
            onChange={(e) => setNote(e.target.value)}
            onBlur={handleNoteBlur}
            placeholder="Your thoughts about this book..."
            rows={3}
            className="mt-3 w-full bg-transparent resize-none text-sm"
          />
        )}
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        <div className="card text-center">
          <BookOpen size={18} className="mx-auto mb-1 text-extract" />
          <p className="text-xl font-bold">{book.verbatimCount || 0}</p>
          <p className="text-xs text-text-tertiary">Extracts</p>
        </div>
        <div className="card text-center">
          <Lightbulb size={18} className="mx-auto mb-1 text-synthesis" />
          <p className="text-xl font-bold">{book.synthesisCount || 0}</p>
          <p className="text-xs text-text-tertiary">Syntheses</p>
        </div>
        <div className="card text-center">
          <Tag size={18} className="mx-auto mb-1 text-skill" />
          <p className="text-xl font-bold">{uniqueTags.size}</p>
          <p className="text-xs text-text-tertiary">Tags</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-border mb-4">
        <button
          onClick={() => setTab('extracts')}
          className={`flex-1 py-3 text-sm font-medium text-center border-b-2 transition-colors ${
            tab === 'extracts'
              ? 'border-extract text-extract'
              : 'border-transparent text-text-tertiary hover:text-text-secondary'
          }`}
        >
          Extracts
        </button>
        <button
          onClick={() => setTab('syntheses')}
          className={`flex-1 py-3 text-sm font-medium text-center border-b-2 transition-colors ${
            tab === 'syntheses'
              ? 'border-synthesis text-synthesis'
              : 'border-transparent text-text-tertiary hover:text-text-secondary'
          }`}
        >
          Syntheses
        </button>
      </div>

      {/* Tab Content */}
      {tab === 'extracts' && (
        <div className="space-y-3">
          {extractsLoading ? (
            <LoadingSpinner />
          ) : extracts.length === 0 ? (
            <EmptyState message="No extracts yet. Open the iOS app to capture passages from your book." />
          ) : (
            extracts.map((e) => <ExtractCard key={e.id} extract={e} bookId={bookId} />)
          )}
        </div>
      )}

      {tab === 'syntheses' && (
        <div className="space-y-3">
          <button
            onClick={() => navigate(`/book/${bookId}/add-synthesis`)}
            className="w-full py-3 rounded-card border-2 border-dashed border-synthesis/30 text-synthesis hover:bg-synthesis/5 transition-colors flex items-center justify-center gap-2"
          >
            <Plus size={18} /> Add Synthesis
          </button>
          {synthesesLoading ? (
            <LoadingSpinner />
          ) : syntheses.length === 0 ? (
            <EmptyState message="No syntheses yet. Write your first takeaway." />
          ) : (
            syntheses.map((s) => <SynthesisCard key={s.id} synthesis={s} bookId={bookId} />)
          )}
        </div>
      )}

      {showDelete && (
        <ConfirmDialog
          title={`Delete ${book.title}?`}
          message={`This will also delete all ${book.verbatimCount || 0} extracts and ${book.synthesisCount || 0} syntheses. This cannot be undone.`}
          onConfirm={handleDelete}
          onCancel={() => setShowDelete(false)}
        />
      )}
    </div>
  )
}
