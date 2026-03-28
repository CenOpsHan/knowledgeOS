import { NavLink } from 'react-router-dom'
import { BookOpen, Star, Tag } from 'lucide-react'

const tabs = [
  { to: '/', icon: BookOpen, label: 'Library' },
  { to: '/skills', icon: Star, label: 'Skills' },
  { to: '/topics', icon: Tag, label: 'Topics' },
]

export default function TabBar() {
  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-surface border-t border-border z-40 md:top-0 md:bottom-auto md:left-0 md:right-auto md:w-20 md:h-screen md:border-t-0 md:border-r">
      <div className="flex md:flex-col items-center justify-around md:justify-start md:pt-6 md:gap-2 h-16 md:h-auto">
        {tabs.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `flex flex-col items-center gap-1 px-3 py-2 rounded-input transition-colors ${
                isActive
                  ? 'text-accent'
                  : 'text-text-tertiary hover:text-text-secondary'
              }`
            }
          >
            <Icon size={22} />
            <span className="text-xs font-medium">{label}</span>
          </NavLink>
        ))}
      </div>
    </nav>
  )
}
