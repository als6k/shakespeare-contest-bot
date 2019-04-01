module Search
  extend self

  LINE_ENDINGS_REGEXP = /[\,\.\;\?\)\]\:\!\-\"\'\ ]+\Z/
  LETTERS_REGEXP = /[^'a-zA-Z]+/
  WORD_REGEXP = /[^[[:word:]]']+/
  WORD_SEPARATORS_REGEXP = /[\,\.\;\?\)\]\:\!\"\ ]/

  def find(question, level)
    case level
    when 1
      eq_search(question).try(:name)
    when 2
      like_search(question)
    when 3
      multi_like_search(2, question)
    when 4
      multi_like_search(3, question)
    when 5
      # ts_search(question)
      like_search_5(question)
    when 6,7
      chars_search(question)
    when 8
      similar_chars_search(question)
    end
  end

 # private

  def eq_search(question)
    Line.where(line: question).first
  end

  def like_search(question)
    q_sql = question.sub('%WORD%', '%')
    Line.where("line LIKE ?", q_sql).pluck(:line).each do |line|
      word = missing_word(line, question)
      return word if word
    end
    nil
  end

  # like_search with unknown replaced word
  def like_search_5(question)
    words = question.split(WORD_REGEXP)
    last_replace_str = question
    q_sql = words.map do |word|
      last_replace_index = last_replace_str.rindex('%')
      last_replace_str = if last_replace_index
        l_part = question[0..last_replace_index]
        r_part = question[(last_replace_index + 1)..-1]
        l_part + r_part.sub(word, '%')
      else
        question.sub(word, '%')
      end
    end
    condition = Array.new(q_sql.size){"line LIKE ?"}.join(' OR ')
    Line.where(condition, *q_sql).limit(20).pluck(:line).each do |line|
      answers = replaced_words(line, question)
      return answers.join(',') if answers
    end
  end

  # like_search for :q_count multiple lines in one work
  def multi_like_search(q_count, question)
    questions = question.split("\n").map{|q| q.sub(LINE_ENDINGS_REGEXP, '')}
    return unless questions.size == q_count
    q_sql = questions.map {|q| q.sub('%WORD%', '%')}
    condition = Array.new(q_count){"line LIKE ?"}.join(' OR ')
    found = Line.where(condition, *q_sql)
      .pluck(:name, :line)
      .each_with_object({}) do |(name,line), h|
        if h[name]
          h[name] << line
        else
          h[name] = [line]
        end
      end
    found.each do |_,lines|
      next if lines.size < q_count
      answers = questions.map do |question|
        word = nil
        lines.each do |line|
          word = missing_word(line, question)
          if word
            lines.delete(line)
            break
          end
        end
        break unless word
        word
      end
      return answers.join(',') if answers
    end
    nil
  end

  # not used: slower than like_search (180ms vs. 60ms)
  def ts_search(question)
    line = Line.search_by_line(question).pluck(:line).first
    answers = replaced_words(line, question)
    answers.join(',') if answers
  end

  # search by chars combination
  def chars_search(question)
    chars = question.gsub(LETTERS_REGEXP, '').chars.sort.join
    Line.where(letters: chars).pluck(:line).first
  end

  def similar_chars_search(question)
    chars = question.gsub(LETTERS_REGEXP, '').chars.sort.join
    Line.search_by_similar_letters(question.length, chars)
      .where("length(letters) = ?", chars.length)
      .pluck(:line).first
  end

  # original_line = 'Our woes into the air; our eyes %WORD% weep'
  # replaced_line = 'Our woes into the air; our eyes governor weep'
  # => 'governor'
  def missing_word(original_line, replaced_line)
    word = original_line.dup
    replaced_line.split('%WORD%').reject(&:blank?).each do |part|
      word.sub!(part, '')
    end
    return nil if word[WORD_SEPARATORS_REGEXP]
    word if replaced_line.sub('%WORD%', word) == original_line
  end

  # original_line = 'Our woes into the air; our eyes do weep'
  # replaced_line = 'Our woes into the air; our eyes governor weep'
  # => ['do', 'governor']
  def replaced_words(original_line, replaced_line)
    o_words = original_line.split(WORD_REGEXP)
    r_words = replaced_line.split(WORD_REGEXP)
    return unless o_words.size == r_words.size
    0.upto(o_words.size - 1) do |i|
      original_word = o_words[i]
      replaced_word = r_words[i]
      unless original_word == replaced_word
        return [original_word, replaced_word]
      end
    end
    nil
  end

  # not used (previous version)
  def replaced_words_v0(original_line, replaced_line)
    original_start = 0
    replaced_start = 0
    original_end = original_line.length - 1
    replaced_end = replaced_line.length - 1

    # first loop to find the start
    0.upto(original_end) do |i|
      break unless original_line[i] == replaced_line[i]
      original_start += 1
      replaced_start += 1
    end

    # now loop again to find the end
    1.upto(original_end) do |i|
      break unless original_line[-i] == replaced_line[-i]
      original_end -= 1
      replaced_end -= 1
    end

    original_word = original_line[original_start..original_end]
    replaced_word = replaced_line[replaced_start..replaced_end]
    return nil if original_word[' '] || replaced_word[' ']
    [original_word, replaced_word]
  end
end
