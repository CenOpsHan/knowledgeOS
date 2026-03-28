import { useState, useMemo } from 'react'
import { X, Search, Quote, Lightbulb } from 'lucide-react'
import { useExtracts } from '../../hooks/useExtracts'
import { useSyntheses } from '../../hooks/useSyntheses'
import { useBooks } from '../../hooks/useBooks'
import TagPill from '../Shared/TagPill'
import { useTags } from '../../hooks/useTags'

export default function KnowledgePicker({
  onClose,
  onLink,
  linkedExtractIds = [],
  linkedSynthesisIds = [],
}) {
  const [filter, setFilter] = useState('all') // all | extracts | syntheses
  const [search, setSearch] = useState('')
  const [bookFilter, setBookFilter] = useState('')
  const [selectedExtracts, setSelectedExtracts] = useState(new Set(linkedExtractIds))
  const [selectedSyntheses, setSelectedSyntheses] = useState(new Set(linkedSynthesisIds))
  const initialExtractIds = new Set(linkedExtractIds)
  const initialSynthesisIds = new Set(linkedSynthesisIds)

  const { extracts } = useExtracts()
  const { syntheses } = useSyntheses()
  const { books } = useBooks()
  const { tags: allTags } = useTags()

  const tagColorMap = Object.fromEntries(allTags.map((t) => [t.name, t.color]))
  const bookMap = Object.fromEntries(books.map((b) => [b.id, b]))

  const filteredExtracts = useMemo(() => {
    if (filter === 'syntheses') return []
    return extracts.filter((e) => {
      if (bookFilter && e.bookId !== bookFilter) return false
      if (search && !e.content?.toLowerCase().includes(search.toLowerCase())) return false
      return true
    })
  }, [extracts, filter, bookFilter, search])

  const filteredSyntheses = useMemo(() => {
    if (filter === 'extracts') return []
    return syntheses.filter((s) => {
      if (bookFilter && s.bookId !== bookFilter) return false
      if (
        search &&
        !s.title?.toLowerCase().includes(search.toLowerCase()) &&
        !s.content?.toLowerCase().includes(search.toLowerCase())
      )
        return false
      return true
    })
  }, [syntheses, filter, bookFilter, search])

  const toggleExtract = (id) => {
    const next = new Set(selectedExtracts)
    next.has(id) ? next.delete(id) : next.add(id)
    setSelectedExtracts(next)
  }

  const toggleSynthesis = (id) => {
    const next = new Set(selectedSyntheses)
    next.has(id) ? next.delete(id) : next.add(id)
    setSelectedSyntheses(next)
  }

  const totalSelected = selectedExtracts.size + selectedSyntheses.size
  const hasChanges = [...selectedExtracts].some(id => !initialExtractIds.has(id)) ||
    [...initialExtractIds].some(id => !selectedExtracts.has(id)) ||
    [...selectedSyntheses].some(id => !initialSynthesisIds.has(id)) ||
    [...initialSynthesisIds].some(id => !selectedSyntheses.has(id))

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="bg-surface border border-border rounded-card w-full max-w-2xl max-h-[80vh] flex flex-col mx-4">
        <div className="flex items-center justify-between px-4 py-3 border-b border-border">
          <h2 className="text-lg font-semibold">Link Knowledge</h2>
          <button onClick={onClose} className="p-1 text-text-tertiary hover:text-text-primary">
            <X size={20} />
          </button>
        </div>

        <div className="px-4 py-3 space-y-3 border-b border-border">
          <div className="flex gap-2">
            {['all', 'extracts', 'syntheses'].map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`pill text-xs ${
                  filter === f
                    ? 'bg-accent text-white'
                    : 'bg-surface-elevated text-text-secondary'
                }`}
              >
                {f.charAt(0).toUpperCase() + f.slice(1)}
              </button>
            ))}
          </div>
          <div className="flex gap-2">
            <div className="relative flex-1">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-tertiary" />
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search..."
                className="w-full pl-9 text-sm"
              />
            </div>
            <select
              value={bookFilter}
              onChange={(e) => setBookFilter(e.target.value)}
              className="text-sm"
            >
              <option value="">All Books</option>
              {books.map((b) => (
                <option key={b.id} value={b.id}>{b.title}</option>
              ))}
            </select>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto px-4 py-2 space-y-2">
          {filteredExtracts.map((e) => (
            <label
              key={e.id}
              className={`flex items-start gap-3 p-3 rounded-card cursor-pointer transition-colors ${
                selectedExtracts.has(e.id) ? 'bg-extract/10' : 'hover:bg-surface-hover'
              }`}
            >
              <input
                type="checkbox"
                checked={selectedExtracts.has(e.id)}
                onChange={() => toggleExtract(e.id)}
                className="mt-1 accent-extract"
              />
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <span className="pill text-[10px] bg-extract/20 text-extract">VERBATIM</span>
                  <span className="text-xs text-text-tertiary">
                    {bookMap[e.bookId]?.title}
                  </span>
                </div>
                <p className="text-sm font-mono text-text-primary line-clamp-2">{e.content}</p>
                <div className="flex gap-1 mt-1">
                  {e.tags?.map((t) => (
                    <TagPill key={t} name={t} color={tagColorMap[t]} />
                  ))}
                </div>
              </div>
            </label>
          ))}

          {filteredSyntheses.map((s) => (
            <label
              key={s.id}
              className={`flex items-start gap-3 p-3 rounded-card cursor-pointer transition-colors ${
                selectedSyntheses.has(s.id) ? 'bg-synthesis/10' : 'hover:bg-surface-hover'
              }`}
            >
              <input
                type="checkbox"
                checked={selectedSyntheses.has(s.id)}
                onChange={() => toggleSynthesis(s.id)}
                className="mt-1 accent-synthesis"
              />
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <span className="pill text-[10px] bg-synthesis/20 text-synthesis">SYNTHESIS</span>
                  <span className="text-xs text-text-tertiary">
                    {bookMap[s.bookId]?.title}
                  </span>
                </div>
                <p className="text-sm font-semibold text-text-primary">{s.title}</p>
                <div className="flex gap-1 mt-1">
                  {s.tags?.map((t) => (
                    <TagPill key={t} name={t} color={tagColorMap[t]} />
                  ))}
                </div>
              </div>
            </label>
          ))}

          {filteredExtracts.length === 0 && filteredSyntheses.length === 0 && (
            <p className="text-center text-text-tertiary py-8">No results found</p>
          )}
        </div>

        <div className="px-4 py-3 border-t border-border">
          <button
            onClick={() => {
              const toLink = [...selectedExtracts].filter((id) => !initialExtractIds.has(id))
              const toLinkSynth = [...selectedSyntheses].filter((id) => !initialSynthesisIds.has(id))
              const toUnlinkExtracts = [...initialExtractIds].filter((id) => !selectedExtracts.has(id))
              const toUnlinkSynth = [...initialSynthesisIds].filter((id) => !selectedSyntheses.has(id))
              onLink(toLink, toLinkSynth, toUnlinkExtracts, toUnlinkSynth)
            }}
            className="btn-primary w-full"
            disabled={!hasChanges}
          >
            Link {totalSelected} Selected
          </button>
        </div>
      </div>
    </div>
  )
}
