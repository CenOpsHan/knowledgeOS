export default function TagPill({ name, color, onRemove, onClick }) {
  return (
    <span
      className="pill cursor-default text-xs"
      style={{
        backgroundColor: color ? `${color}26` : 'rgba(99,102,241,0.15)',
        color: color || '#6366F1',
      }}
      onClick={onClick}
    >
      {name}
      {onRemove && (
        <button
          onClick={(e) => {
            e.stopPropagation()
            onRemove()
          }}
          className="ml-1 hover:opacity-70"
        >
          &times;
        </button>
      )}
    </span>
  )
}
