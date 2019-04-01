require 'httparty'
require 'nokogiri'

ROOT_PAGE_URL = 'http://shakespeare.mit.edu/'.freeze
DATA_FOLDER = 'data'
POETRY = ['Poetry/LoversComplaint.html',
          'Poetry/RapeOfLucrece.html',
          'Poetry/VenusAndAdonis.html',
          'Poetry/elegy.html']

w_links = POETRY.map{|p| ROOT_PAGE_URL + p}

w_links.each do |w_link|
  w_doc = HTTParty::get(w_link)
  w_parsed = Nokogiri::HTML(w_doc)

  w_name = w_parsed.css('h1')[0].try(:text)
  file_name = "#{w_name}.txt"

  lines = if w_link.ends_with?('elegy.html')
    w_parsed.css('td').map(&:text).reject!{|t| t.to_i > 0 || t.blank?}
  else
    w_parsed.css('blockquote').map(&:text).map{|b_text| b_text.split("\n")}.flatten
  end

  file_path = File.join(Rails.root, DATA_FOLDER, file_name)
  File.open(file_path, 'w') do |f|
    lines.each do |row|
      stripped_line = row.strip
      f << "#{stripped_line}\n" unless stripped_line.blank?
    end
  end
end
