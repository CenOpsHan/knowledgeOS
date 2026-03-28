import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { X } from 'lucide-react'
import { useAuth } from '../hooks/useAuth'
import { createSynthesis } from '../services/firestore'
import MarkdownEditor from '../components/Shared/MarkdownEditor'
import TagInput from '../components/Shared/TagInput'

export default function AddSynthesisPage() {
  const { bookId } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()

  const [title, setTitle] = useState('')
  const [content, setContent] = useState('')
  const [pageReferences, setPageReferences] = useState('')
  const [tags, setTags] = useState([])
  const [saving, setSaving] = useState(false)

  const handleSave = async () => {
    if (!title.trim() || !user) return
    setSaving(true)
    try {
      const id = await createSynthesis(user.uid, {
        bookId,
        title: title.trim(),
        content,
        pageReferences: pageReferences || null,
        tags,
      })
      navigate(`/book/${bookId}/synthesis/${id}`)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-bg overflow-y-auto">
      <div className="max-w-2xl mx-auto px-4 py-6">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold">New Synthesis</h2>
          <div className="flex items-center gap-2">
            <button onClick={() => navigate(-1)} className="btn-secondary text-sm">Cancel</button>
            <button
              onClick={handleSave}
              disabled={!title.trim() || saving}
              className="btn-primary text-sm disabled:opacity-50"
            >
              {saving ? 'Saving...' : 'Save'}
            </button>
          </div>
        </div>

        <div className="space-y-4">
          <div>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Give this takeaway a title..."
              className="w-full text-lg font-semibold"
            />
          </div>

          <MarkdownEditor
            value={content}
            onChange={setContent}
            placeholder="Write your interpretation, framework, or key takeaway..."
          />

          <div>
            <label className="block text-sm text-text-secondary mb-1">
              Page References
            </label>
            <input
              type="text"
              value={pageReferences}
              onChange={(e) => setPageReferences(e.target.value)}
              placeholder="e.g. Ch. 4, pp. 88-102"
              className="w-full"
            />
          </div>

          <div>
            <label className="block text-sm text-text-secondary mb-2">Tags</label>
            <TagInput selectedTags={tags} onTagsChange={setTags} />
          </div>
        </div>
      </div>
    </div>
  )
}
