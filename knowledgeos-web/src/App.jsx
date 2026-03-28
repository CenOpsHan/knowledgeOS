import { useState } from 'react'
import { Routes, Route } from 'react-router-dom'
import { AuthProvider } from './hooks/useAuth'
import AuthGate from './components/Layout/AuthGate'
import TabBar from './components/Layout/TabBar'
import TopBar from './components/Layout/TopBar'
import GlobalSearch from './components/Shared/GlobalSearch'

import LibraryPage from './pages/LibraryPage'
import AddBookPage from './pages/AddBookPage'
import BookDetailPage from './pages/BookDetailPage'
import ExtractDetailPage from './pages/ExtractDetailPage'
import AddSynthesisPage from './pages/AddSynthesisPage'
import SynthesisDetailPage from './pages/SynthesisDetailPage'
import SkillsPage from './pages/SkillsPage'
import CreateSkillPage from './pages/CreateSkillPage'
import SkillDetailPage from './pages/SkillDetailPage'
import TopicsPage from './pages/TopicsPage'
import TopicDetailPage from './pages/TopicDetailPage'

export default function App() {
  const [searchOpen, setSearchOpen] = useState(false)

  return (
    <AuthProvider>
      <AuthGate>
        <div className="min-h-screen pb-20 md:pl-20 md:pb-0">
          <TopBar onSearchClick={() => setSearchOpen(true)} />
          <main className="max-w-content mx-auto px-4 py-6">
            <Routes>
              <Route path="/" element={<LibraryPage />} />
              <Route path="/add-book" element={<AddBookPage />} />
              <Route path="/book/:bookId" element={<BookDetailPage />} />
              <Route path="/book/:bookId/extract/:extractId" element={<ExtractDetailPage />} />
              <Route path="/book/:bookId/add-synthesis" element={<AddSynthesisPage />} />
              <Route path="/book/:bookId/synthesis/:synthesisId" element={<SynthesisDetailPage />} />
              <Route path="/skills" element={<SkillsPage />} />
              <Route path="/skills/new" element={<CreateSkillPage />} />
              <Route path="/skill/:skillId" element={<SkillDetailPage />} />
              <Route path="/topics" element={<TopicsPage />} />
              <Route path="/topic/:tagName" element={<TopicDetailPage />} />
            </Routes>
          </main>
          <TabBar />
        </div>
        {searchOpen && <GlobalSearch onClose={() => setSearchOpen(false)} />}
      </AuthGate>
    </AuthProvider>
  )
}
