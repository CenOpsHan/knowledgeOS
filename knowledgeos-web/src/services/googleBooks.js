const API_URL = 'https://www.googleapis.com/books/v1/volumes'

export async function searchBooks(query) {
  if (!query || query.length < 3) return []

  const res = await fetch(`${API_URL}?q=${encodeURIComponent(query)}&maxResults=8`)
  if (!res.ok) throw new Error('Google Books search failed')

  const data = await res.json()
  if (!data.items) return []

  return data.items.map((item) => {
    const v = item.volumeInfo || {}
    const isbn = (v.industryIdentifiers || []).find((i) => i.type === 'ISBN_13')
    const thumbnail = v.imageLinks?.thumbnail?.replace('http:', 'https:') || null

    return {
      googleBooksId: item.id,
      title: v.title || '',
      authors: v.authors || [],
      coverUrl: thumbnail,
      pageCount: v.pageCount || null,
      publisher: v.publisher || null,
      publishedDate: v.publishedDate || null,
      isbn: isbn?.identifier || null,
    }
  })
}
