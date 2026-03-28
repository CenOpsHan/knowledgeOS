# KnowledgeOS

Personal knowledge management app — capture, organize, and synthesize knowledge from books.

## Architecture

Two codebases sharing one Firebase backend:
- **Web** (`knowledgeos-web/`): React + Vite + Tailwind CSS v4 — power-editing, keyboard-heavy
- **iOS** (`KnowledgeOS/`): SwiftUI + MVVM — capture device (camera + OCR)

## Firebase Project

- Project ID: `knowledgeos-80279`
- Auth: Google Sign-In only
- Firestore: User-scoped collections under `users/{userId}/`
- Storage: Source photos for OCR extracts
- Collections: `books`, `extracts`, `syntheses`, `skills`, `tags`

## Web App

### Setup
```bash
cd knowledgeos-web
npm install
npm run dev      # Dev server on :5173
npm run build    # Production build to dist/
```

### Key Files
- `src/firebase.js` — Firebase init (real config already set)
- `src/services/firestore.js` — All Firestore CRUD operations
- `src/hooks/` — React hooks wrapping Firestore subscriptions
- `src/pages/` — All 12 screens (Library, Skills, Topics tabs)
- `src/components/` — Shared, Library, Skills, Topics, Layout
- `src/styles/global.css` — Tailwind v4 theme tokens (`@theme` block)
- `src/styles/theme.js` — JS color constants and tag palette

### Tailwind v4 Notes
- Uses CSS-based config (`@import "tailwindcss"` + `@theme {}`) — no `tailwind.config.js`
- PostCSS plugin is `@tailwindcss/postcss` (not `tailwindcss`)
- Typography plugin via `@plugin "@tailwindcss/typography"`

## iOS App

### Setup
1. Open Xcode, create new iOS App project (bundle ID: `com.knowledgeos.app`)
2. Delete default files, copy `KnowledgeOS/KnowledgeOS/` source folders in
3. Add SPM dependencies:
   - `https://github.com/firebase/firebase-ios-sdk` (11.0.0+) → FirebaseAuth, FirebaseFirestore, FirebaseStorage
   - `https://github.com/google/GoogleSignIn-iOS` (8.0.0+) → GoogleSignIn, GoogleSignInSwift
   - `https://github.com/gonzalezreal/swift-markdown-ui` (2.4.0+) → MarkdownUI
4. Add `GoogleService-Info.plist` from `Config/` to the target
5. Add URL scheme for Google Sign-In (reversed client ID from plist)
6. Build target: iOS 17.0+

### Key Files
- `App/KnowledgeOSApp.swift` — Entry point, Firebase configure
- `Services/` — AuthService, FirestoreService, StorageService, OCRService, GoogleBooksService
- `ViewModels/` — MVVM view models with Firestore subscriptions
- `Views/` — Library, Skills, Topics, Search screens
- `Models/` — Book, Extract, Synthesis, Skill, Tag (Codable)
- `Config/Theme.swift` — Color constants matching web theme

## Firebase Deploy

```bash
firebase login
firebase deploy --only firestore:rules,firestore:indexes,storage --project knowledgeos-80279
```

Files: `firestore.rules`, `firestore.indexes.json`, `storage.rules`, `firebase.json`

## Data Model

- **Book**: title, authors, coverUrl, status (reading/finished/wishlist), rating, personalNote, verbatimCount, synthesisCount
- **Extract**: bookId, content (verbatim text), pageNumber, chapter, tags[], sourcePhotoPaths[], linkedSkillIds[]
- **Synthesis**: bookId, title, content (markdown), pageReferences, tags[], linkedSkillIds[]
- **Skill**: name, icon (emoji), description, sections[{title, content, linkedExtractIds[], linkedSynthesisIds[]}]
- **Tag**: name (= document ID), color

## QA Status

Two QA passes completed. Fixed bugs:
- Firestore batch 500-op limit (chunked batches) — web + iOS
- Tag Codable decoding (excluded `name` from decoding) — iOS
- OCR double-resume crash (guard flag) — iOS
- Main thread mutations from Firestore callbacks — iOS
- Auth state listener thread safety — iOS
- TopicDetailPage auto-expand (useState→useEffect) — web
- KnowledgePicker unlink behavior — web
- Skill delete dismiss — iOS
- PersonalNote keystroke debounce — iOS
- PhotosPicker duplicate photos — iOS

### Remaining items to verify on Mac
- [ ] iOS builds and runs in Xcode simulator
- [ ] Google Sign-In flow works on both platforms
- [ ] Firestore reads/writes work end-to-end
- [ ] OCR text extraction from camera photos
- [ ] Composite indexes deployed (`firestore.indexes.json`)
- [ ] All 12 screens render correctly on both platforms
