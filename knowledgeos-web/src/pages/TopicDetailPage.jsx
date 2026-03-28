import { useState, useMemo, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, MoreHorizontal, ChevronDown, ChevronRight } from 'lucide-react'
import { useAuth } from '../hooks/useAuth'
import { useTags } from '../hooks/useTags'
import { useExtracts } from '../hooks/useExtracts'
import { useSyntheses } from '../hooks/useSyntheses'
import { useBooks } from '../hooks/useBooks'
import { useSkills } from '../hooks/useSkills'
import { updateTag, deleteTag } from '../services/firestore'
import { tagColorPalette } from '../styles/theme'
import ExtractCard from '../components/Library/ExtractCard'
import SynthesisCard from '../components/Library/SynthesisCard'
import ConfirmDialog from '../components/Shared/ConfirmDialog'
import LoadingSpinner from '../components/Shared/LoadingSpinner'

export default function TopicDetailPage() {
  const { tagName } = useParams()
  const decodedTag = decodeURIComponent(tagName)
  const navigate = useNavigate()
  const { user } = useAuth()
  const { tags, loading: tagsLoading } = useTags()
  const { extracts } = useExtracts()
  const { syntheses } = useSyntheses()
  const { books } = useBooks()
  const { skills } = useSkills()

  const [filter, setFilter] = useState('all')
  const [expandedBooks, setExpandedBooks] = useState(new Set())
  const [showMenu, setShowMenu] = useState(false)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const [showRename, setShowRename] = useState(false)
  const [newName, setNewName] = useState(decodedTag)
  const [showColorPicker, setShowColorPicker] = useState(false)

  const tag = tags.find((t) => t.name === decodedTag)

  const taggedExtracts = useMemo(
    () => extracts.filter((e) => (e.tags || []).includes(decodedTag)),
    [extracts, decodedTag]
  )

  const taggedSyntheses = useMemo(
    () => syntheses.filter((s) => (s.tags || []).includes(decodedTag)),
    [syntheses, decodedTag]
  )

  const bookMap = Object.fromEntries(books.map((b) => [b.id, b]))
  const bookIds = [...new Set([
    ...taggedExtracts.map((e) => e.bookId),
    ...taggedSyntheses.map((s) => s.bookId),
  ])]

  // Auto-expand all books when data loads
  useEffect(() => {
    if (bookIds.length > 0) setExpandedBooks(new Set(bookIds))
  }, [bookIds.join(',')])

  const relatedSkills = skills.filter((s) =>
    s.sections?.some((sec) => {
      const linkedIds = [...(sec.linkedExtractIds || []), ...(sec.linkedSynthesisIds || [])]
      return linkedIds.some((id) =>
        taggedExtracts.some((e) => e.id === id) || taggedSyntheses.some((s) => s.id === id)
      )
    })
  )

  const toggleBook = (bookId) => {
    const next = new Set(expandedBooks)
    next.has(bookId) ? next.delete(bookId) : next.add(bookId)
    setExpandedBooks(next)
  }

  const handleRename = async () => {
    if (!user || !newName.trim()) return
    await updateTag(user.uid, decodedTag, newName.toLowerCase().trim(), tag?.color || '#6366F1')
    navigate(`/topic/${encodeURIComponent(newName.toLowerCase().trim())}`, { replace: true })
    setShowRename(false)
  }

  const handleColorChange = async (color) => {
    if (!user) return
    await updateTag(user.uid, decodedTag, decodedTag, color)
    setShowColorPicker(false)
  }

  const handleDelete = async () => {
    if (!user) return
    await deleteTag(user.uid, decodedTag)
    navigate('/topics')
  }

  if (tagsLoading) return <LoadingSpinner />
  if (!tag) return (
    <div className="text-center py-16">
      <p className="text-text-secondary">Tag &quot;{decodedTag}&quot; not found</p>
      <button onClick={() => navigate('/topics')} className="mt-4 text-accent hover:underline">Back to Topics</button>
    </div>
  )

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <button onClick={() => navigate('/topics')} className="flex items-center gap-1 text-text-secondary hover:text-text-primary">
          <ArrowLeft size={20} /> Back
        </button>
        <div className="relative">
          <button onClick={() => setShowMenu(!showMenu)} className="p-2 text-text-secondary hover:text-text-primary">
            <MoreHorizontal size={20} />
          </button>
          {showMenu && (
            <div className="absolute right-0 top-full mt-1 bg-surface-elevated border border-border rounded-card py-1 min-w-[160px] z-20">
              <button onClick={() => { setShowMenu(false); setShowRename(true) }} className="w-full text-left px-4 py-2 text-sm hover:bg-surface-hover">Rename</button>
              <button onClick={() => { setShowMenu(false); setShowColorPicker(true) }} className="w-full text-left px-4 py-2 text-sm hover:bg-surface-hover">Change Color</button>
              <button onClick={() => { setShowMenu(false); setShowDeleteConfirm(true) }} className="w-full text-left px-4 py-2 text-sm text-destructive hover:bg-surface-hover">Delete Tag</button>
            </div>
          )}
        </div>
      </div>

      <div className="flex items-center gap-3 mb-2">
        <span className="w-4 h-4 rounded-full" style={{ backgroundColor: tag.color }} />
        <h1 className="text-2xl font-bold">{decodedTag}</h1>
      </div>

      <p className="text-sm text-text-secondary mb-6">
        {taggedExtracts.length} extracts · {taggedSyntheses.length} syntheses across {bookIds.length} books
      </p>

      <div className="flex gap-2 mb-4">
        {['all', 'extracts', 'syntheses'].map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`pill text-sm ${filter === f ? 'bg-accent text-white' : 'bg-surface-elevated text-text-secondary'}`}
          >
            {f === 'all' ? 'All' : f === 'extracts' ? 'Extracts Only' : 'Syntheses Only'}
          </button>
        ))}
      </div>

      <div className="space-y-4">
        {bookIds.map((bookId) => {
          const book = bookMap[bookId]
          if (!book) return null
          const bookExtracts = filter !== 'syntheses' ? taggedExtracts.filter((e) => e.bookId === bookId) : []
          const bookSyntheses = filter !== 'extracts' ? taggedSyntheses.filter((s) => s.bookId === bookId) : []
          const count = bookExtracts.length + bookSyntheses.length
          if (count === 0) return null

          return (
            <div key={bookId} className="card">
              <button onClick={() => toggleBook(bookId)} className="flex items-center gap-3 w-full text-left">
                <div className="w-8 h-12 rounded bg-surface-elevated overflow-hidden shrink-0">
                  {book.coverUrl ? <img src={book.coverUrl} alt="" className="w-full h-full object-cover" /> : <div className="w-full h-full bg-accent/20" />}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold truncate">{book.title}</p>
                  <p className="text-xs text-text-tertiary">{count} items</p>
                </div>
                {expandedBooks.has(bookId) ? <ChevronDown size={18} /> : <ChevronRight size={18} />}
              </button>

              {expandedBooks.has(bookId) && (
                <div className="mt-3 space-y-2">
                  {bookExtracts.map((e) => <ExtractCard key={e.id} extract={e} bookId={bookId} />)}
                  {bookSyntheses.map((s) => <SynthesisCard key={s.id} synthesis={s} bookId={bookId} />)}
                </div>
              )}
            </div>
          )
        })}
      </div>

      {relatedSkills.length > 0 && (
        <div className="mt-6">
          <h3 className="text-sm font-semibold text-text-secondary mb-2">Also in Skills</h3>
          <div className="space-y-2">
            {relatedSkills.map((s) => (
              <button
                key={s.id}
                onClick={() => navigate(`/skill/${s.id}`)}
                className="flex items-center gap-2 text-sm text-text-primary hover:text-accent"
              >
                <span>{s.icon || '📚'}</span> {s.name}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Rename modal */}
      {showRename && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60" onClick={() => setShowRename(false)}>
          <div className="bg-surface-elevated border border-border rounded-card p-6 max-w-sm w-full mx-4" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-lg font-semibold mb-4">Rename Tag</h3>
            <input type="text" value={newName} onChange={(e) => setNewName(e.target.value)} className="w-full mb-4" />
            <div className="flex gap-3 justify-end">
              <button onClick={() => setShowRename(false)} className="btn-secondary">Cancel</button>
              <button onClick={handleRename} className="btn-primary">Rename</button>
            </div>
          </div>
        </div>
      )}

      {/* Color picker */}
      {showColorPicker && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60" onClick={() => setShowColorPicker(false)}>
          <div className="bg-surface-elevated border border-border rounded-card p-6 max-w-sm w-full mx-4" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-lg font-semibold mb-4">Change Color</h3>
            <div className="flex flex-wrap gap-3">
              {tagColorPalette.map((color) => (
                <button
                  key={color}
                  onClick={() => handleColorChange(color)}
                  className={`w-8 h-8 rounded-full border-2 transition-colors ${tag.color === color ? 'border-white' : 'border-transparent hover:border-white/30'}`}
                  style={{ backgroundColor: color }}
                />
              ))}
            </div>
          </div>
        </div>
      )}

      {showDeleteConfirm && (
        <ConfirmDialog
          title={`Delete "${decodedTag}"?`}
          message="This will remove the tag from all extracts and syntheses."
          onConfirm={handleDelete}
          onCancel={() => setShowDeleteConfirm(false)}
        />
      )}
    </div>
  )
}
