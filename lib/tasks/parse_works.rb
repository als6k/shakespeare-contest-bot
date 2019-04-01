require 'httparty'
require 'nokogiri'

ROOT_PAGE_URL = 'http://shakespeare.mit.edu/'
SCENE_PAGE_REGEXP = /.*\.(\d+)\.(\d+)\.html/
DATA_FOLDER = 'data'

works_doc = HTTParty::get(ROOT_PAGE_URL)
works_parsed = Nokogiri::HTML(works_doc)
w_links = works_parsed.css('table[border] a').map {|e| e['href']}

w_links.reject!{|l| l.starts_with?('Poetry')}
# ["allswell/index.html", "asyoulikeit/index.html", ...]
w_links.each do |w_link|
  scenes_doc = HTTParty::get(ROOT_PAGE_URL + w_link)
  scenes_parsed = Nokogiri::HTML(scenes_doc)

  w_name = scenes_parsed.css('.play').text.chomp
  s_links = scenes_parsed.css('p a').map{ |a| [a.text, a.attr('href')] }

  puts "#{w_name}"
  s_links.each do |s_name, s_link|
    a_number, s_number = s_link.scan(SCENE_PAGE_REGEXP)[0]
    next if a_number.nil? || s_number.nil?

    file_name = "#{w_name}. Act #{a_number}, Scene #{s_number}: #{s_name}.txt"
    s_url = ROOT_PAGE_URL + w_link.sub('index.html', s_link)
    scene_doc = HTTParty::get(s_url)
    scene_parsed = Nokogiri::HTML(scene_doc)
    lines = scene_parsed.css('blockquote a[name]').map(&:text)

    file_path = File.join(Rails.root, DATA_FOLDER, file_name)
    File.open(file_path, 'w') do |f|
      lines.each { |row| f << "#{row.strip}\n" }
    end
  end

  sleep 5
end
