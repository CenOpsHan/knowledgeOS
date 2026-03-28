import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, MoreHorizontal, Image } from 'lucide-react'
import { useAuth } from '../hooks/useAuth'
import { useBooks } from '../hooks/useBooks'
import { useSkills } from '../hooks/useSkills'
import { getExtract, updateExtract, deleteExtract } from '../services/firestore'
import { getPhotoURLs } from '../services/storage'
import TagInput from '../components/Shared/TagInput'
import ConfirmDialog from '../components/Shared/ConfirmDialog'
import LoadingSpinner from '../components/Shared/LoadingSpinner'

export default function ExtractDetailPage() {
  const { bookId, extractId } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const { books } = useBooks()
  const { skills } = useSkills()

  const [extract, setExtract] = useState(null)
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState(false)
  const [editForm, setEditForm] = useState({})
  const [showDelete, setShowDelete] = useState(false)
  const [showPhotos, setShowPhotos] = useState(false)
  const [photoURLs, setPhotoURLs] = useState([])
  const [showMenu, setShowMenu] = useState(false)

  const book = books.find((b) => b.id === bookId)

  useEffect(() => {
    if (!user) return
    getExtract(user.uid, extractId).then((data) => {
      setExtract(data)
      setEditForm({
        content: data?.content || '',
        pageNumber: data?.pageNumber || '',
        pageRange: data?.pageRange || '',
        chapter: data?.chapter || '',
      })
      setLoading(false)
    })
  }, [user, extractId])

  useEffect(() => {
    if (extract?.sourcePhotoPaths?.length > 0) {
      getPhotoURLs(extract.sourcePhotoPaths).then(setPhotoURLs)
    }
  }, [extract?.sourcePhotoPaths])

  if (loading) return <LoadingSpinner />
  if (!extract) return <p className="text-text-secondary text-center py-16">Extract not found</p>

  const linkedSkills = skills.filter((s) =>
    extract.linkedSkillIds?.includes(s.id)
  )

  const handleSave = async () => {
    if (!user || !editForm.content.trim()) return
    await updateExtract(user.uid, extractId, {
      content: editForm.content,
      pageNumber: editForm.pageNumber ? Number(editForm.pageNumber) : null,
      pageRange: editForm.pageRange || null,
      chapter: editForm.chapter || null,
    })
    setExtract({ ...extract, ...editForm })
    setEditing(false)
  }

  const handleTagsChange = async (tags) => {
    if (!user) return
    await updateExtract(user.uid, extractId, { tags })
    setExtract({ ...extract, tags })
  }

  const handleDelete = async () => {
    if (!user) return
    await deleteExtract(user.uid, extractId, bookId)
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

      <span className="pill bg-extract/20 text-extract text-xs font-semibold mb-4 inline-block">VERBATIM</span>

      {(extract.pageNumber || extract.pageRange) && (
        <p className="text-sm text-text-secondary mb-4">
          {extract.pageRange ? `Pages ${extract.pageRange}` : `Page ${extract.pageNumber}`}
          {extract.chapter && ` · ${extract.chapter}`}
        </p>
      )}

      <div className="border-l-[3px] border-extract bg-extract-dim rounded-r-card p-6 mb-6 relative">
        <span className="text-4xl text-extract/30 absolute top-2 left-4 font-serif">"</span>
        {editing ? (
          <div className="space-y-3">
            <textarea
              value={editForm.content}
              onChange={(e) => setEditForm({ ...editForm, content: e.target.value })}
              rows={6}
              className="w-full font-mono text-sm bg-transparent resize-none"
            />
            <div className="grid grid-cols-3 gap-3">
              <input
                type="number"
                value={editForm.pageNumber}
                onChange={(e) => setEditForm({ ...editForm, pageNumber: e.target.value })}
                placeholder="Page #"
                className="text-sm"
              />
              <input
                type="text"
                value={editForm.pageRange}
                onChange={(e) => setEditForm({ ...editForm, pageRange: e.target.value })}
                placeholder="Page range"
                className="text-sm"
              />
              <input
                type="text"
                value={editForm.chapter}
                onChange={(e) => setEditForm({ ...editForm, chapter: e.target.value })}
                placeholder="Chapter"
                className="text-sm"
              />
            </div>
          </div>
        ) : (
          <p className="font-mono text-sm text-text-primary whitespace-pre-wrap pt-6">
            {extract.content}
          </p>
        )}
      </div>

      {/* Source Photos */}
      {photoURLs.length > 0 && (
        <div className="mb-6">
          <button
            onClick={() => setShowPhotos(!showPhotos)}
            className="flex items-center gap-2 text-sm text-text-secondary hover:text-text-primary"
          >
            <Image size={16} />
            View source photo{photoURLs.length > 1 ? 's' : ''} ({photoURLs.length})
          </button>
          {showPhotos && (
            <div className="mt-3 grid grid-cols-2 gap-3">
              {photoURLs.map((url, i) => (
                <img key={i} src={url} alt={`Source ${i + 1}`} className="rounded-card border border-border" />
              ))}
            </div>
          )}
        </div>
      )}

      {/* Tags */}
      <div className="mb-6">
        <h3 className="text-sm font-semibold text-text-secondary mb-2">Tags</h3>
        <TagInput selectedTags={extract.tags || []} onTagsChange={handleTagsChange} />
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
          title="Delete Extract?"
          message="This extract will be permanently deleted."
          onConfirm={handleDelete}
          onCancel={() => setShowDelete(false)}
        />
      )}
    </div>
  )
}
