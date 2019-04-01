DATA_FOLDER = 'data'

Line.delete_all

Dir[File.join(Rails.root, DATA_FOLDER, '*.txt')].each do |file_path|
  name = File.basename(file_path, '.txt')

  if name.starts_with?('sonnnet-')
    first_line = File.open(file_path, &:readline)
    name = name.split('-').last
    name << '. ' << first_line.sub(/\P{L}+\Z/, '')
  end

  puts name

  File.readlines(file_path).each do |line|
    line = line.sub(/\P{L}+\Z/, '').strip

    if line.present?
      letters = line.gsub(Search::LETTERS_REGEXP, '').chars.sort.join
      Line.create!(name: name, line: line, letters: letters)
    end
  end
end
