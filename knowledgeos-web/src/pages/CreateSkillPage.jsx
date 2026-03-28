import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { X, Plus } from 'lucide-react'
import { useAuth } from '../hooks/useAuth'
import { createSkill } from '../services/firestore'
import SkillSectionEditor from '../components/Skills/SkillSectionEditor'

function generateId() {
  return Math.random().toString(36).substring(2, 15)
}

export default function CreateSkillPage() {
  const navigate = useNavigate()
  const { user } = useAuth()

  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [icon, setIcon] = useState('📚')
  const [sections, setSections] = useState([
    { id: generateId(), title: '', content: '', linkedExtractIds: [], linkedSynthesisIds: [], order: 0 },
  ])
  const [saving, setSaving] = useState(false)
  const [showEmojiInput, setShowEmojiInput] = useState(false)

  const handleSectionChange = (index, updated) => {
    setSections(sections.map((s, i) => (i === index ? updated : s)))
  }

  const addSection = () => {
    setSections([
      ...sections,
      { id: generateId(), title: '', content: '', linkedExtractIds: [], linkedSynthesisIds: [], order: sections.length },
    ])
  }

  const removeSection = (index) => {
    if (sections.length <= 1) return
    setSections(sections.filter((_, i) => i !== index).map((s, i) => ({ ...s, order: i })))
  }

  const handleSave = async () => {
    if (!name.trim() || !user) return
    setSaving(true)
    try {
      const id = await createSkill(user.uid, {
        name: name.trim(),
        description,
        icon,
        sections: sections.map((s, i) => ({ ...s, order: i })),
      })
      navigate(`/skill/${id}`)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-bg overflow-y-auto">
      <div className="max-w-2xl mx-auto px-4 py-6">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold">New Skill</h2>
          <button onClick={() => navigate(-1)} className="p-2 text-text-secondary hover:text-text-primary">
            <X size={24} />
          </button>
        </div>

        <div className="space-y-4">
          <div className="flex items-center gap-4">
            <div className="relative">
              <button
                onClick={() => setShowEmojiInput(!showEmojiInput)}
                className="w-16 h-16 rounded-card bg-surface-elevated border border-border flex items-center justify-center text-3xl hover:border-border-hover transition-colors"
              >
                {icon}
              </button>
              {showEmojiInput && (
                <div className="absolute top-full left-0 mt-2 bg-surface-elevated border border-border rounded-card p-3 z-20">
                  <input
                    type="text"
                    value={icon}
                    onChange={(e) => {
                      const val = e.target.value
                      if (val) setIcon(val.slice(-2))
                    }}
                    className="w-20 text-center text-2xl"
                    placeholder="emoji"
                  />
                  <p className="text-xs text-text-tertiary mt-1">Type or paste emoji</p>
                </div>
              )}
            </div>
            <div className="flex-1">
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g. SEO Playbook, Leadership Framework"
                className="w-full text-lg font-semibold mb-2"
              />
              <input
                type="text"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="What is this skill about?"
                className="w-full text-sm"
              />
            </div>
          </div>

          <div className="space-y-4 mt-6">
            <h3 className="text-sm font-semibold text-text-secondary">Sections</h3>
            {sections.map((section, index) => (
              <SkillSectionEditor
                key={section.id}
                section={section}
                onChange={(updated) => handleSectionChange(index, updated)}
                onDelete={() => removeSection(index)}
              />
            ))}
            <button
              onClick={addSection}
              className="w-full py-3 rounded-card border-2 border-dashed border-border text-text-secondary hover:text-text-primary hover:border-border-hover transition-colors flex items-center justify-center gap-2"
            >
              <Plus size={18} /> Add Another Section
            </button>
          </div>

          <button
            onClick={handleSave}
            disabled={!name.trim() || saving}
            className="btn-primary w-full mt-6 disabled:opacity-50"
          >
            {saving ? 'Creating...' : 'Create Skill'}
          </button>
        </div>
      </div>
    </div>
  )
}
