require 'httparty'
require 'nokogiri'

ROOT_PAGE_URL = 'http://shakespeare.mit.edu/Poetry/sonnets.html'
SONNET_PAGE_REGEXP = /sonnet\.([A-Z]+)\.html/
DATA_FOLDER = 'data'

sonnets_doc = HTTParty::get(ROOT_PAGE_URL)
sonnets_parsed = Nokogiri::HTML(sonnets_doc)
s_links = sonnets_parsed.css('dt a').map{ |a| [a.text, a.attr('href')] }

s_links.each do |s_name, s_link|
  s_number = s_link.scan(SONNET_PAGE_REGEXP)[0].try(:first)
  next if s_number.nil?

  file_name = "sonnnet-#{s_number}.txt"
  s_url = ROOT_PAGE_URL.sub('sonnets.html', s_link)
  sonnet_doc = HTTParty::get(s_url)
  sonnet_parsed = Nokogiri::HTML(sonnet_doc)
  lines = sonnet_parsed.css('blockquote').map(&:text).map{|b_text| b_text.split("\n")}.flatten

  file_path = File.join(Rails.root, DATA_FOLDER, file_name)
  File.open(file_path, 'w') do |f|
    lines.each { |row| f << "#{row.strip}\n" }
  end
end
