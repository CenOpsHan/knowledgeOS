import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, MoreHorizontal } from 'lucide-react'
import { useAuth } from '../hooks/useAuth'
import { useSkills } from '../hooks/useSkills'
import { getSynthesis, updateSynthesis, deleteSynthesis } from '../services/firestore'
import MarkdownRenderer from '../components/Shared/MarkdownRenderer'
import MarkdownEditor from '../components/Shared/MarkdownEditor'
import TagInput from '../components/Shared/TagInput'
import ConfirmDialog from '../components/Shared/ConfirmDialog'
import LoadingSpinner from '../components/Shared/LoadingSpinner'

export default function SynthesisDetailPage() {
  const { bookId, synthesisId } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const { skills } = useSkills()

  const [synthesis, setSynthesis] = useState(null)
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState(false)
  const [editForm, setEditForm] = useState({})
  const [showDelete, setShowDelete] = useState(false)
  const [showMenu, setShowMenu] = useState(false)

  useEffect(() => {
    if (!user) return
    getSynthesis(user.uid, synthesisId).then((data) => {
      setSynthesis(data)
      setEditForm({
        title: data?.title || '',
        content: data?.content || '',
        pageReferences: data?.pageReferences || '',
      })
      setLoading(false)
    })
  }, [user, synthesisId])

  if (loading) return <LoadingSpinner />
  if (!synthesis) return <p className="text-text-secondary text-center py-16">Synthesis not found</p>

  const linkedSkills = skills.filter((s) =>
    synthesis.linkedSkillIds?.includes(s.id)
  )

  const handleSave = async () => {
    if (!user || !editForm.title.trim()) return
    await updateSynthesis(user.uid, synthesisId, {
      title: editForm.title,
      content: editForm.content,
      pageReferences: editForm.pageReferences || null,
    })
    setSynthesis({ ...synthesis, ...editForm })
    setEditing(false)
  }

  const handleTagsChange = async (tags) => {
    if (!user) return
    await updateSynthesis(user.uid, synthesisId, { tags })
    setSynthesis({ ...synthesis, tags })
  }

  const handleDelete = async () => {
    if (!user) return
    await deleteSynthesis(user.uid, synthesisId, bookId)
    navigate(`/book/${bookId}`)
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <button onClick={() => navigate(`/book/${bookId}`)} className="flex items-center gap-1 text-text-secondary hover:text-text-primary">
          <ArrowLeft size={20} /> Back
        </button>
        <div className="flex items-center gap-2">
          {editing ? (
            <>
              <button onClick={() => setEditing(false)} className="btn-secondary text-sm">Cancel</button>
              <button onClick={handleSave} className="btn-primary text-sm">Save</button>
            </>
          ) : (
            <div className="relative">
              <button onClick={() => setShowMenu(!showMenu)} className="p-2 text-text-secondary hover:text-text-primary">
                <MoreHorizontal size={20} />
              </button>
              {showMenu && (
                <div className="absolute right-0 top-full mt-1 bg-surface-elevated border border-border rounded-card py-1 min-w-[140px] z-20">
                  <button onClick={() => { setShowMenu(false); setEditing(true) }} className="w-full text-left px-4 py-2 text-sm text-text-primary hover:bg-surface-hover">Edit</button>
                  <button onClick={() => { setShowMenu(false); setShowDelete(true) }} className="w-full text-left px-4 py-2 text-sm text-destructive hover:bg-surface-hover">Delete</button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      <span className="pill bg-synthesis/20 text-synthesis text-xs font-semibold mb-4 inline-block">SYNTHESIS</span>

      {editing ? (
        <div className="space-y-4 mb-6">
          <input
            type="text"
            value={editForm.title}
            onChange={(e) => setEditForm({ ...editForm, title: e.target.value })}
            className="w-full text-xl font-bold"
          />
          <MarkdownEditor
            value={editForm.content}
            onChange={(content) => setEditForm({ ...editForm, content })}
          />
          <input
            type="text"
            value={editForm.pageReferences}
            onChange={(e) => setEditForm({ ...editForm, pageReferences: e.target.value })}
            placeholder="Page references"
            className="w-full text-sm"
          />
        </div>
      ) : (
        <>
          <h1 className="text-2xl font-bold mb-2">{synthesis.title}</h1>
          {synthesis.pageReferences && (
            <p className="text-sm text-text-tertiary mb-4">{synthesis.pageReferences}</p>
          )}
          <div className="border-l-[3px] border-synthesis bg-synthesis-dim rounded-r-card p-6 mb-6">
            <MarkdownRenderer content={synthesis.content} />
          </div>
        </>
      )}

      {/* Tags */}
      <div className="mb-6">
        <h3 className="text-sm font-semibold text-text-secondary mb-2">Tags</h3>
        <TagInput selectedTags={synthesis.tags || []} onTagsChange={handleTagsChange} />
      </div>

      {/* Linked Skills */}
      <div className="mb-6">
        <h3 className="text-sm font-semibold text-text-secondary mb-2">Used in Skills</h3>
        {linkedSkills.length === 0 ? (
          <p className="text-sm text-text-tertiary">Not linked to any skills</p>
        ) : (
          <div className="space-y-2">
            {linkedSkills.map((s) => (
              <button
                key={s.id}
                onClick={() => navigate(`/skill/${s.id}`)}
                className="flex items-center gap-2 text-sm text-text-primary hover:text-accent"
              >
                <span>{s.icon || '📚'}</span>
                {s.name}
              </button>
            ))}
          </div>
        )}
      </div>

      {showDelete && (
        <ConfirmDialog
          title="Delete Synthesis?"
          message="This synthesis will be permanently deleted."
          onConfirm={handleDelete}
          onCancel={() => setShowDelete(false)}
        />
      )}
    </div>
  )
}
