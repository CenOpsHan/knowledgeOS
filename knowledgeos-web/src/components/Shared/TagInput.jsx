import { useState, useRef } from 'react'
import { useTags } from '../../hooks/useTags'
import { useAuth } from '../../hooks/useAuth'
import { createTag } from '../../services/firestore'
import { tagColorPalette } from '../../styles/theme'
import TagPill from './TagPill'

export default function TagInput({ selectedTags, onTagsChange }) {
  const { user } = useAuth()
  const { tags: allTags } = useTags()
  const [input, setInput] = useState('')
  const [showSuggestions, setShowSuggestions] = useState(false)
  const [showColorPicker, setShowColorPicker] = useState(false)
  const [newTagName, setNewTagName] = useState('')
  const inputRef = useRef(null)

  const suggestions = allTags.filter(
    (t) =>
      t.name.toLowerCase().includes(input.toLowerCase()) &&
      !selectedTags.includes(t.name)
  )

  const handleAddTag = (tagName) => {
    if (!selectedTags.includes(tagName)) {
      onTagsChange([...selectedTags, tagName])
    }
    setInput('')
    setShowSuggestions(false)
  }

  const handleRemoveTag = (tagName) => {
    onTagsChange(selectedTags.filter((t) => t !== tagName))
  }

  const handleCreateTag = async (color) => {
    const name = newTagName.toLowerCase().trim()
    if (!name || !user) return
    await createTag(user.uid, name, color)
    handleAddTag(name)
    setShowColorPicker(false)
    setNewTagName('')
  }

  const tagColorMap = Object.fromEntries(allTags.map((t) => [t.name, t.color]))

  return (
    <div className="space-y-2">
      <div className="flex flex-wrap gap-1.5">
        {selectedTags.map((tag) => (
          <TagPill
            key={tag}
            name={tag}
            color={tagColorMap[tag]}
            onRemove={() => handleRemoveTag(tag)}
          />
        ))}
      </div>

      <div className="relative">
        <input
          ref={inputRef}
          type="text"
          value={input}
          onChange={(e) => {
            setInput(e.target.value)
            setShowSuggestions(true)
          }}
          onFocus={() => setShowSuggestions(true)}
          onBlur={() => setTimeout(() => setShowSuggestions(false), 200)}
          placeholder="Add tag..."
          className="w-full text-sm"
        />

        {showSuggestions && input.length > 0 && (
          <div className="absolute z-20 top-full left-0 right-0 mt-1 bg-surface-elevated border border-border rounded-input max-h-48 overflow-y-auto">
            {suggestions.map((tag) => (
              <button
                key={tag.name}
                onMouseDown={() => handleAddTag(tag.name)}
                className="w-full text-left px-3 py-2 text-sm text-text-primary hover:bg-surface-hover flex items-center gap-2"
              >
                <span
                  className="w-3 h-3 rounded-full"
                  style={{ backgroundColor: tag.color }}
                />
                {tag.name}
              </button>
            ))}
            {!allTags.some((t) => t.name === input.toLowerCase().trim()) && (
              <button
                onMouseDown={() => {
                  setNewTagName(input.trim())
                  setShowColorPicker(true)
                  setShowSuggestions(false)
                }}
                className="w-full text-left px-3 py-2 text-sm text-accent hover:bg-surface-hover"
              >
                Create "{input.trim()}"
              </button>
            )}
          </div>
        )}
      </div>

      {showColorPicker && (
        <div className="bg-surface-elevated border border-border rounded-card p-3">
          <p className="text-sm text-text-secondary mb-2">
            Pick a color for "{newTagName}"
          </p>
          <div className="flex flex-wrap gap-2">
            {tagColorPalette.map((color) => (
              <button
                key={color}
                onClick={() => handleCreateTag(color)}
                className="w-7 h-7 rounded-full border-2 border-transparent hover:border-white/30 transition-colors"
                style={{ backgroundColor: color }}
              />
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
