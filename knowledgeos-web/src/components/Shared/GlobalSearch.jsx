import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { X, Search, BookOpen, Quote, Lightbulb, Star } from 'lucide-react'
import { useSearch } from '../../hooks/useSearch'

function Highlight({ text, query }) {
  if (!query || !text) return text
  const idx = text.toLowerCase().indexOf(query.toLowerCase())
  if (idx === -1) return text
  return (
    <>
      {text.slice(0, idx)}
      <mark className="bg-accent/30 text-text-primary rounded px-0.5">
        {text.slice(idx, idx + query.length)}
      </mark>
      {text.slice(idx + query.length)}
    </>
  )
}

export default function GlobalSearch({ onClose }) {
  const [query, setQuery] = useState('')
  const [debouncedQuery, setDebouncedQuery] = useState('')
  const navigate = useNavigate()
  const inputRef = useRef(null)

  useEffect(() => {
    inputRef.current?.focus()
  }, [])

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedQuery(query), 300)
    return () => clearTimeout(timer)
  }, [query])

  const { results, totalResults } = useSearch(debouncedQuery)

  const goTo = (path) => {
    onClose()
    navigate(path)
  }

  return (
    <div className="fixed inset-0 z-50 bg-bg/95 backdrop-blur-sm flex flex-col">
      <div className="max-w-content mx-auto w-full px-4 pt-6">
        <div className="flex items-center gap-3 mb-6">
          <div className="relative flex-1">
            <Search size={20} className="absolute left-4 top-1/2 -translate-y-1/2 text-text-tertiary" />
            <input
              ref={inputRef}
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search your knowledge base..."
              className="w-full pl-12 pr-4 py-3 text-lg bg-surface-elevated"
            />
          </div>
          <button onClick={onClose} className="p-2 text-text-secondary hover:text-text-primary">
            <X size={24} />
          </button>
        </div>

        {!debouncedQuery && (
          <p className="text-text-tertiary text-center py-16">
            Search your knowledge base
          </p>
        )}

        {debouncedQuery && totalResults === 0 && (
          <p className="text-text-tertiary text-center py-16">
            No results for "{debouncedQuery}"
          </p>
        )}

        <div className="overflow-y-auto max-h-[calc(100vh-120px)] space-y-6">
          {results.books.length > 0 && (
            <section>
              <h3 className="text-xs font-semibold text-text-tertiary uppercase tracking-wider mb-2 flex items-center gap-2">
                <BookOpen size={14} /> Books
              </h3>
              {results.books.map((b) => (
                <button
                  key={b.id}
                  onClick={() => goTo(`/book/${b.id}`)}
                  className="w-full text-left px-3 py-2 rounded-input hover:bg-surface-hover flex items-center gap-3"
                >
                  <div className="w-8 h-12 rounded bg-surface-elevated overflow-hidden shrink-0">
                    {b.coverUrl ? (
                      <img src={b.coverUrl} alt="" className="w-full h-full object-cover" />
                    ) : (
                      <div className="w-full h-full bg-accent/20" />
                    )}
                  </div>
                  <div>
                    <p className="text-sm text-text-primary">
                      <Highlight text={b.title} query={debouncedQuery} />
                    </p>
                    <p className="text-xs text-text-secondary">
                      <Highlight text={b.authors?.join(', ')} query={debouncedQuery} />
                    </p>
                  </div>
                </button>
              ))}
            </section>
          )}

          {results.extracts.length > 0 && (
            <section>
              <h3 className="text-xs font-semibold text-text-tertiary uppercase tracking-wider mb-2 flex items-center gap-2">
                <Quote size={14} /> Extracts
              </h3>
              {results.extracts.map((e) => (
                <button
                  key={e.id}
                  onClick={() => goTo(`/book/${e.bookId}/extract/${e.id}`)}
                  className="w-full text-left px-3 py-2 rounded-input hover:bg-surface-hover"
                >
                  <p className="text-sm font-mono text-text-primary line-clamp-2">
                    <Highlight text={e.content?.substring(0, 150)} query={debouncedQuery} />
                  </p>
                </button>
              ))}
            </section>
          )}

          {results.syntheses.length > 0 && (
            <section>
              <h3 className="text-xs font-semibold text-text-tertiary uppercase tracking-wider mb-2 flex items-center gap-2">
                <Lightbulb size={14} /> Syntheses
              </h3>
              {results.syntheses.map((s) => (
                <button
                  key={s.id}
                  onClick={() => goTo(`/book/${s.bookId}/synthesis/${s.id}`)}
                  className="w-full text-left px-3 py-2 rounded-input hover:bg-surface-hover"
                >
                  <p className="text-sm font-semibold text-text-primary">
                    <Highlight text={s.title} query={debouncedQuery} />
                  </p>
                  <p className="text-xs text-text-secondary line-clamp-1">
                    <Highlight text={s.content?.substring(0, 100)} query={debouncedQuery} />
                  </p>
                </button>
              ))}
            </section>
          )}

          {results.skills.length > 0 && (
            <section>
              <h3 className="text-xs font-semibold text-text-tertiary uppercase tracking-wider mb-2 flex items-center gap-2">
                <Star size={14} /> Skills
              </h3>
              {results.skills.map((s) => (
                <button
                  key={s.id}
                  onClick={() => goTo(`/skill/${s.id}`)}
                  className="w-full text-left px-3 py-2 rounded-input hover:bg-surface-hover flex items-center gap-2"
                >
                  <span className="text-lg">{s.icon || '📚'}</span>
                  <p className="text-sm text-text-primary">
                    <Highlight text={s.name} query={debouncedQuery} />
                  </p>
                </button>
              ))}
            </section>
          )}
        </div>
      </div>
    </div>
  )
}
