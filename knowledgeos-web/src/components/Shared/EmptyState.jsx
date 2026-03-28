export default function EmptyState({ message, action, onAction }) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <p className="text-text-secondary text-lg mb-4">{message}</p>
      {action && onAction && (
        <button onClick={onAction} className="btn-primary">
          {action}
        </button>
      )}
    </div>
  )
}
