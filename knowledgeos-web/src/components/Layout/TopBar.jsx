import { Search } from 'lucide-react'

export default function TopBar({ onSearchClick }) {
  return (
    <header className="sticky top-0 z-30 bg-bg/80 backdrop-blur-md border-b border-border px-4 py-3 flex items-center justify-between">
      <h1 className="text-lg font-bold font-mono text-text-primary">
        KnowledgeOS
      </h1>
      <button
        onClick={onSearchClick}
        className="p-2 rounded-input text-text-secondary hover:text-text-primary hover:bg-surface-elevated transition-colors"
      >
        <Search size={20} />
      </button>
    </header>
  )
}
