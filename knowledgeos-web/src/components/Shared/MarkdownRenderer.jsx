import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'

export default function MarkdownRenderer({ content }) {
  return (
    <div className="prose prose-invert prose-sm max-w-none prose-headings:text-text-primary prose-p:text-text-primary prose-li:text-text-primary prose-strong:text-text-primary prose-code:bg-surface-elevated prose-code:px-1 prose-code:py-0.5 prose-code:rounded prose-code:text-accent-light prose-pre:bg-surface-elevated prose-blockquote:border-accent/30">
      <ReactMarkdown remarkPlugins={[remarkGfm]}>{content || ''}</ReactMarkdown>
    </div>
  )
}
