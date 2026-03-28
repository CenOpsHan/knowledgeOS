import { useState, useMemo } from 'react'
import { useBooks } from './useBooks'
import { useExtracts } from './useExtracts'
import { useSyntheses } from './useSyntheses'
import { useSkills } from './useSkills'

export function useSearch(query) {
  const { books } = useBooks()
  const { extracts } = useExtracts()
  const { syntheses } = useSyntheses()
  const { skills } = useSkills()

  const results = useMemo(() => {
    if (!query || query.length < 2) {
      return { books: [], extracts: [], syntheses: [], skills: [] }
    }

    const q = query.toLowerCase()

    return {
      books: books.filter(
        (b) =>
          b.title?.toLowerCase().includes(q) ||
          b.authors?.some((a) => a.toLowerCase().includes(q))
      ),
      extracts: extracts.filter((e) => e.content?.toLowerCase().includes(q)),
      syntheses: syntheses.filter(
        (s) =>
          s.title?.toLowerCase().includes(q) ||
          s.content?.toLowerCase().includes(q)
      ),
      skills: skills.filter(
        (s) =>
          s.name?.toLowerCase().includes(q) ||
          s.sections?.some((sec) => sec.content?.toLowerCase().includes(q))
      ),
    }
  }, [query, books, extracts, syntheses, skills])

  const totalResults =
    results.books.length +
    results.extracts.length +
    results.syntheses.length +
    results.skills.length

  return { results, totalResults }
}
