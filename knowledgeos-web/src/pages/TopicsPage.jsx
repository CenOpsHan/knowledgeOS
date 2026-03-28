import { useState, useMemo } from 'react'
import { Cloud, List } from 'lucide-react'
import { useTags } from '../hooks/useTags'
import { useExtracts } from '../hooks/useExtracts'
import { useSyntheses } from '../hooks/useSyntheses'
import TagCloud from '../components/Topics/TagCloud'
import TagList from '../components/Topics/TagList'
import EmptyState from '../components/Shared/EmptyState'
import LoadingSpinner from '../components/Shared/LoadingSpinner'

export default function TopicsPage() {
  const { tags, loading } = useTags()
  const { extracts } = useExtracts()
  const { syntheses } = useSyntheses()
  const [view, setView] = useState('cloud')
  const [search, setSearch] = useState('')

  const counts = useMemo(() => {
    const c = {}
    tags.forEach((t) => { c[t.name] = 0 })
    extracts.forEach((e) => (e.tags || []).forEach((t) => { c[t] = (c[t] || 0) + 1 }))
    syntheses.forEach((s) => (s.tags || []).forEach((t) => { c[t] = (c[t] || 0) + 1 }))
    return c
  }, [tags, extracts, syntheses])

  const filtered = tags.filter((t) =>
    t.name.toLowerCase().includes(search.toLowerCase())
  )

  if (loading) return <LoadingSpinner />

  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-bold">
          Topics
          <span className="text-text-tertiary font-normal ml-2 text-base">{tags.length}</span>
        </h2>
        <div className="flex gap-1">
          <button
            onClick={() => setView('cloud')}
            className={`p-2 rounded-input ${view === 'cloud' ? 'text-accent bg-accent-dim' : 'text-text-tertiary hover:text-text-primary'}`}
          >
            <Cloud size={18} />
          </button>
          <button
            onClick={() => setView('list')}
            className={`p-2 rounded-input ${view === 'list' ? 'text-accent bg-accent-dim' : 'text-text-tertiary hover:text-text-primary'}`}
          >
            <List size={18} />
          </button>
        </div>
      </div>

      <input
        type="text"
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        placeholder="Filter tags..."
        className="w-full mb-4"
      />

      {filtered.length === 0 ? (
        <EmptyState message="No tags yet. Start tagging your extracts and syntheses." />
      ) : view === 'cloud' ? (
        <TagCloud tags={filtered} counts={counts} />
      ) : (
        <TagList tags={filtered} counts={counts} />
      )}
    </div>
  )
}
