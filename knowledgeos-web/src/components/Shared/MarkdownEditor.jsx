import { useState, useRef } from 'react'
import TextareaAutosize from 'react-textarea-autosize'
import { Bold, Italic, Heading2, Heading3, List, ListOrdered, Code } from 'lucide-react'
import MarkdownRenderer from './MarkdownRenderer'

const toolbar = [
  { icon: Bold, prefix: '**', suffix: '**', label: 'Bold' },
  { icon: Italic, prefix: '_', suffix: '_', label: 'Italic' },
  { icon: Heading2, prefix: '## ', suffix: '', label: 'H2' },
  { icon: Heading3, prefix: '### ', suffix: '', label: 'H3' },
  { icon: List, prefix: '- ', suffix: '', label: 'Bullet list' },
  { icon: ListOrdered, prefix: '1. ', suffix: '', label: 'Numbered list' },
  { icon: Code, prefix: '```\n', suffix: '\n```', label: 'Code block' },
]

export default function MarkdownEditor({ value, onChange, placeholder, minRows = 8 }) {
  const [preview, setPreview] = useState(false)
  const textareaRef = useRef(null)

  const insertFormat = (prefix, suffix) => {
    const ta = textareaRef.current
    if (!ta) return
    const start = ta.selectionStart
    const end = ta.selectionEnd
    const selected = value.substring(start, end)
    const newText = value.substring(0, start) + prefix + selected + suffix + value.substring(end)
    onChange(newText)
    setTimeout(() => {
      ta.focus()
      ta.selectionStart = start + prefix.length
      ta.selectionEnd = start + prefix.length + selected.length
    }, 0)
  }

  return (
    <div className="border border-border rounded-card overflow-hidden">
      <div className="flex items-center justify-between px-3 py-2 border-b border-border bg-surface">
        <div className="flex gap-1">
          {!preview &&
            toolbar.map(({ icon: Icon, prefix, suffix, label }) => (
              <button
                key={label}
                onClick={() => insertFormat(prefix, suffix)}
                className="p-1.5 rounded text-text-tertiary hover:text-text-primary hover:bg-surface-hover transition-colors"
                title={label}
              >
                <Icon size={16} />
              </button>
            ))}
        </div>
        <button
          onClick={() => setPreview(!preview)}
          className="text-xs font-medium px-2 py-1 rounded text-text-secondary hover:text-text-primary hover:bg-surface-hover transition-colors"
        >
          {preview ? 'Edit' : 'Preview'}
        </button>
      </div>

      {preview ? (
        <div className="p-4 min-h-[200px]">
          <MarkdownRenderer content={value} />
        </div>
      ) : (
        <TextareaAutosize
          ref={textareaRef}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          minRows={minRows}
          className="w-full p-4 bg-transparent border-0 resize-none focus:ring-0 text-text-primary placeholder-text-tertiary"
        />
      )}
    </div>
  )
}
