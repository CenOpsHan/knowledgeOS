import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, Edit3, ChevronDown, ChevronRight, Plus, Link2, X, Trash2 } from 'lucide-react'
import { useAuth } from '../hooks/useAuth'
import { useBooks } from '../hooks/useBooks'
import { getSkill, updateSkill, deleteSkill, linkKnowledgeToSkill, unlinkKnowledgeFromSkill } from '../services/firestore'
import { useExtracts } from '../hooks/useExtracts'
import { useSyntheses } from '../hooks/useSyntheses'
import MarkdownRenderer from '../components/Shared/MarkdownRenderer'
import MarkdownEditor from '../components/Shared/MarkdownEditor'
import SkillSectionEditor from '../components/Skills/SkillSectionEditor'
import KnowledgePicker from '../components/Skills/KnowledgePicker'
import ConfirmDialog from '../components/Shared/ConfirmDialog'
import LoadingSpinner from '../components/Shared/LoadingSpinner'

function generateId() {
  return Math.random().toString(36).substring(2, 15)
}

export default function SkillDetailPage() {
  const { skillId } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const { books } = useBooks()
  const { extracts: allExtracts } = useExtracts()
  const { syntheses: allSyntheses } = useSyntheses()

  const [skill, setSkill] = useState(null)
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState(false)
  const [editForm, setEditForm] = useState({})
  const [expandedSections, setExpandedSections] = useState(new Set())
  const [showDelete, setShowDelete] = useState(false)
  const [pickerSectionId, setPickerSectionId] = useState(null)

  const bookMap = Object.fromEntries(books.map((b) => [b.id, b]))
  const extractMap = Object.fromEntries(allExtracts.map((e) => [e.id, e]))
  const synthesisMap = Object.fromEntries(allSyntheses.map((s) => [s.id, s]))

  const loadSkill = async () => {
    if (!user) return
    const data = await getSkill(user.uid, skillId)
    setSkill(data)
    setEditForm({
      name: data?.name || '',
      description: data?.description || '',
      icon: data?.icon || '📚',
      sections: data?.sections || [],
    })
    if (data?.sections) {
      setExpandedSections(new Set(data.sections.map((s) => s.id)))
    }
    setLoading(false)
  }

  useEffect(() => { loadSkill() }, [user, skillId])

  if (loading) return <LoadingSpinner />
  if (!skill) return <p className="text-text-secondary text-center py-16">Skill not found</p>

  const handleSave = async () => {
    if (!user) return
    await updateSkill(user.uid, skillId, {
      name: editForm.name,
      description: editForm.description,
      icon: editForm.icon,
      sections: editForm.sections.map((s, i) => ({ ...s, order: i })),
    })
    setSkill({ ...skill, ...editForm })
    setEditing(false)
  }

  const handleDeleteSkill = async () => {
    if (!user) return
    await deleteSkill(user.uid, skillId)
    navigate('/skills')
  }

  const toggleSection = (id) => {
    const next = new Set(expandedSections)
    next.has(id) ? next.delete(id) : next.add(id)
    setExpandedSections(next)
  }

  const handleLink = async (sectionId, extractIds, synthesisIds, unlinkExtractIds = [], unlinkSynthIds = []) => {
    if (!user) return
    if (extractIds.length > 0 || synthesisIds.length > 0) {
      await linkKnowledgeToSkill(user.uid, skillId, sectionId, extractIds, synthesisIds)
    }
    for (const id of unlinkExtractIds) {
      await unlinkKnowledgeFromSkill(user.uid, skillId, sectionId, 'extract', id)
    }
    for (const id of unlinkSynthIds) {
      await unlinkKnowledgeFromSkill(user.uid, skillId, sectionId, 'synthesis', id)
    }
    await loadSkill()
    setPickerSectionId(null)
  }

  const handleUnlink = async (sectionId, type, itemId) => {
    if (!user) return
    await unlinkKnowledgeFromSkill(user.uid, skillId, sectionId, type, itemId)
    await loadSkill()
  }

  const addSection = () => {
    setEditForm({
      ...editForm,
      sections: [
        ...editForm.sections,
        { id: generateId(), title: '', content: '', linkedExtractIds: [], linkedSynthesisIds: [], order: editForm.sections.length },
      ],
    })
  }

  const formatDate = (ts) => {
    if (!ts) return ''
    const d = ts.toDate ? ts.toDate() : new Date(ts)
    return d.toLocaleDateString()
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <button onClick={() => navigate('/skills')} className="flex items-center gap-1 text-text-secondary hover:text-text-primary">
          <ArrowLeft size={20} /> Back
        </button>
        {editing ? (
          <div className="flex gap-2">
            <button onClick={() => setEditing(false)} className="btn-secondary text-sm">Cancel</button>
            <button onClick={handleSave} className="btn-primary text-sm">Done</button>
          </div>
        ) : (
          <button onClick={() => setEditing(true)} className="btn-secondary text-sm flex items-center gap-1">
            <Edit3 size={14} /> Edit
          </button>
        )}
      </div>

      {editing ? (
        <div className="space-y-4">
          <div className="flex items-center gap-4">
            <input
              type="text"
              value={editForm.icon}
              onChange={(e) => setEditForm({ ...editForm, icon: e.target.value.slice(-2) || '📚' })}
              className="w-16 h-16 text-center text-3xl rounded-card"
            />
            <div className="flex-1">
              <input
                type="text"
                value={editForm.name}
                onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                className="w-full text-lg font-bold mb-2"
              />
              <input
                type="text"
                value={editForm.description}
                onChange={(e) => setEditForm({ ...editForm, description: e.target.value })}
                className="w-full text-sm"
              />
            </div>
          </div>

          <h3 className="text-sm font-semibold text-text-secondary mt-6">Sections</h3>
          {editForm.sections.map((section, index) => (
            <SkillSectionEditor
              key={section.id}
              section={section}
              onChange={(updated) => {
                const sections = [...editForm.sections]
                sections[index] = updated
                setEditForm({ ...editForm, sections })
              }}
              onDelete={() => {
                if (editForm.sections.length <= 1) return
                setEditForm({
                  ...editForm,
                  sections: editForm.sections.filter((_, i) => i !== index),
                })
              }}
            />
          ))}
          <button onClick={addSection} className="w-full py-3 rounded-card border-2 border-dashed border-border text-text-secondary hover:text-text-primary flex items-center justify-center gap-2">
            <Plus size={18} /> Add Section
          </button>

          <button onClick={() => setShowDelete(true)} className="btn-destructive w-full mt-4">
            <Trash2 size={16} className="inline mr-2" /> Delete Skill
          </button>
        </div>
      ) : (
        <>
          <div className="flex items-start gap-4 mb-2">
            <span className="text-4xl">{skill.icon || '📚'}</span>
            <div>
              <h1 className="text-2xl font-bold">{skill.name}</h1>
              <p className="text-text-secondary mt-1">{skill.description}</p>
              <p className="text-xs text-text-tertiary mt-2">
                Created {formatDate(skill.dateCreated)} · Last modified {formatDate(skill.dateModified)}
              </p>
            </div>
          </div>

          <div className="space-y-3 mt-6">
            {(skill.sections || []).map((section) => (
              <div key={section.id} className="card">
                <button
                  onClick={() => toggleSection(section.id)}
                  className="flex items-center justify-between w-full text-left"
                >
                  <h3 className="font-semibold">{section.title || 'Untitled Section'}</h3>
                  {expandedSections.has(section.id) ? <ChevronDown size={18} /> : <ChevronRight size={18} />}
                </button>

                {expandedSections.has(section.id) && (
                  <div className="mt-4">
                    <MarkdownRenderer content={section.content} />

                    {/* Linked Knowledge */}
                    <div className="mt-4 space-y-2">
                      {(section.linkedExtractIds || []).map((eid) => {
                        const ext = extractMap[eid]
                        if (!ext) return null
                        return (
                          <div key={eid} className="flex items-start gap-2 p-2 rounded bg-extract-dim border-l-2 border-extract">
                            <p className="font-mono text-xs text-text-primary line-clamp-2 flex-1">{ext.content}</p>
                            <span className="text-[10px] text-text-tertiary shrink-0">
                              from {bookMap[ext.bookId]?.title}
                              {ext.pageNumber && `, p. ${ext.pageNumber}`}
                            </span>
                            <button
                              onClick={() => handleUnlink(section.id, 'extract', eid)}
                              className="shrink-0 text-text-tertiary hover:text-destructive"
                            >
                              <X size={14} />
                            </button>
                          </div>
                        )
                      })}
                      {(section.linkedSynthesisIds || []).map((sid) => {
                        const syn = synthesisMap[sid]
                        if (!syn) return null
                        return (
                          <div key={sid} className="flex items-start gap-2 p-2 rounded bg-synthesis-dim border-l-2 border-synthesis">
                            <div className="flex-1 min-w-0">
                              <p className="text-sm font-semibold text-text-primary">{syn.title}</p>
                              <span className="text-[10px] text-text-tertiary">from {bookMap[syn.bookId]?.title}</span>
                            </div>
                            <button
                              onClick={() => handleUnlink(section.id, 'synthesis', sid)}
                              className="shrink-0 text-text-tertiary hover:text-destructive"
                            >
                              <X size={14} />
                            </button>
                          </div>
                        )
                      })}
                    </div>

                    <button
                      onClick={() => setPickerSectionId(section.id)}
                      className="mt-3 text-sm text-accent hover:text-accent-light flex items-center gap-1"
                    >
                      <Link2 size={14} /> Link Knowledge
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>
        </>
      )}

      {pickerSectionId && (
        <KnowledgePicker
          onClose={() => setPickerSectionId(null)}
          onLink={(extractIds, synthesisIds, unlinkExtracts, unlinkSynths) => handleLink(pickerSectionId, extractIds, synthesisIds, unlinkExtracts, unlinkSynths)}
          linkedExtractIds={skill.sections?.find((s) => s.id === pickerSectionId)?.linkedExtractIds || []}
          linkedSynthesisIds={skill.sections?.find((s) => s.id === pickerSectionId)?.linkedSynthesisIds || []}
        />
      )}

      {showDelete && (
        <ConfirmDialog
          title="Delete Skill?"
          message="This skill and all its section links will be permanently deleted."
          onConfirm={handleDeleteSkill}
          onCancel={() => setShowDelete(false)}
        />
      )}
    </div>
  )
}
