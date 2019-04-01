class Line < ApplicationRecord
  include PgSearch

  # not used because it's still slower than LIKE
  pg_search_scope :search_by_line,
    against: :line,
    using: {
      tsearch: {
        dictionary: 'simple',
        any_word: true,
        tsvector_column: 'tsv'
      }
    }

  pg_search_scope :search_by_similar_letters, lambda { |line_length, query|
    raise ArgumentError if line_length.to_i == 0
    threshold = 0.01 * line_length + 0.35
    {
      against: :letters,
      using: { trigram: { threshold: threshold } },
      query: query
    }
  }

end
