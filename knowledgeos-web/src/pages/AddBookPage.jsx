import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { X } from 'lucide-react'
import { useAuth } from '../hooks/useAuth'
import { createBook } from '../services/firestore'
import BookSearchInput from '../components/Library/BookSearchInput'

export default function AddBookPage() {
  const navigate = useNavigate()
  const { user } = useAuth()
  const [form, setForm] = useState({
    title: '',
    authors: '',
    coverUrl: null,
    coverStoragePath: null,
    isbn: null,
    pageCount: '',
    publisher: '',
    publishedDate: '',
    googleBooksId: null,
    status: 'reading',
  })
  const [saving, setSaving] = useState(false)

  const handleSelect = (book) => {
    if (!book) return // manual mode
    setForm({
      title: book.title,
      authors: book.authors?.join(', ') || '',
      coverUrl: book.coverUrl,
      coverStoragePath: null,
      isbn: book.isbn,
      pageCount: book.pageCount || '',
      publisher: book.publisher || '',
      publishedDate: book.publishedDate || '',
      googleBooksId: book.googleBooksId,
      status: 'reading',
    })
  }

  const handleSave = async () => {
    if (!form.title.trim() || !user) return
    setSaving(true)
    try {
      const bookId = await createBook(user.uid, {
        title: form.title.trim(),
        authors: form.authors ? form.authors.split(',').map((a) => a.trim()).filter(Boolean) : [],
        coverUrl: form.coverUrl,
        coverStoragePath: form.coverStoragePath,
        isbn: form.isbn,
        pageCount: form.pageCount ? Number(form.pageCount) : null,
        publisher: form.publisher || null,
        publishedDate: form.publishedDate || null,
        googleBooksId: form.googleBooksId,
        status: form.status,
      })
      navigate(`/book/${bookId}`)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-bg overflow-y-auto">
      <div className="max-w-lg mx-auto px-4 py-6">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold">Add Book</h2>
          <button onClick={() => navigate(-1)} className="p-2 text-text-secondary hover:text-text-primary">
            <X size={24} />
          </button>
        </div>

        <div className="mb-6">
          <BookSearchInput onSelect={handleSelect} />
        </div>

        <div className="space-y-4">
          {form.coverUrl && (
            <div className="flex justify-center">
              <img
                src={form.coverUrl}
                alt={form.title}
                className="w-28 h-auto rounded-lg shadow-lg"
              />
            </div>
          )}

          <div>
            <label className="block text-sm text-text-secondary mb-1">Title *</label>
            <input
              type="text"
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
              placeholder="Book title"
              className="w-full"
            />
          </div>

          <div>
            <label className="block text-sm text-text-secondary mb-1">Author(s)</label>
            <input
              type="text"
              value={form.authors}
              onChange={(e) => setForm({ ...form, authors: e.target.value })}
              placeholder="Comma-separated"
              className="w-full"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-text-secondary mb-1">Pages</label>
              <input
                type="number"
                value={form.pageCount}
                onChange={(e) => setForm({ ...form, pageCount: e.target.value })}
                className="w-full"
              />
            </div>
            <div>
              <label className="block text-sm text-text-secondary mb-1">ISBN</label>
              <input
                type="text"
                value={form.isbn || ''}
                onChange={(e) => setForm({ ...form, isbn: e.target.value })}
                className="w-full"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm text-text-secondary mb-1">Publisher</label>
            <input
              type="text"
              value={form.publisher}
              onChange={(e) => setForm({ ...form, publisher: e.target.value })}
              className="w-full"
            />
          </div>

          <div>
            <label className="block text-sm text-text-secondary mb-2">Status</label>
            <div className="flex gap-2">
              {['reading', 'completed', 'shelved'].map((s) => (
                <button
                  key={s}
                  onClick={() => setForm({ ...form, status: s })}
                  className={`pill text-sm flex-1 justify-center ${
                    form.status === s
                      ? 'bg-accent text-white'
                      : 'bg-surface-elevated text-text-secondary border border-border'
                  }`}
                >
                  {s.charAt(0).toUpperCase() + s.slice(1)}
                </button>
              ))}
            </div>
          </div>

          <button
            onClick={handleSave}
            disabled={!form.title.trim() || saving}
            className="btn-primary w-full mt-6 disabled:opacity-50"
          >
            {saving ? 'Adding...' : 'Add to Library'}
          </button>
        </div>
      </div>
    </div>
  )
}
