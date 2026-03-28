import { GripVertical, Trash2 } from 'lucide-react'
import MarkdownEditor from '../Shared/MarkdownEditor'

export default function SkillSectionEditor({ section, onChange, onDelete }) {
  return (
    <div className="card space-y-3">
      <div className="flex items-center gap-2">
        <GripVertical size={16} className="text-text-tertiary cursor-grab" />
        <input
          type="text"
          value={section.title}
          onChange={(e) => onChange({ ...section, title: e.target.value })}
          placeholder="Section title"
          className="flex-1 font-semibold"
        />
        <button
          onClick={onDelete}
          className="p-1.5 rounded text-text-tertiary hover:text-destructive hover:bg-destructive/10 transition-colors"
        >
          <Trash2 size={16} />
        </button>
      </div>
      <MarkdownEditor
        value={section.content}
        onChange={(content) => onChange({ ...section, content })}
        placeholder="Write section content..."
        minRows={4}
      />
    </div>
  )
}
