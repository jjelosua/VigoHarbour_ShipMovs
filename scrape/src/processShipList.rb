# encoding: utf-8
require 'open-uri'
require 'fileutils'
require 'nokogiri'

LOG_SUBDIR = '../logs'
INPUT_FILES_SUBDIR = '../html'
INPUT_FILE = '2012_11_01_apvigo.html'
OUTPUT_FILES_SUBDIR = '../txt'
OUTPUT_FILE = '2012_11_01_shipList.txt'

FileUtils.makedirs(LOG_SUBDIR)
FileUtils.makedirs(OUTPUT_FILES_SUBDIR)

$log_file = File.open("#{LOG_SUBDIR}/processShipList.log", 'w')
output_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{OUTPUT_FILE}", 'w')
page=Nokogiri::HTML(open("#{INPUT_FILES_SUBDIR}/#{INPUT_FILE}"))
links = page.css('a')
if links.length > 0 
  count = 0
  links[0..-1].each do |link|
    nameShip = link.text.strip
    href = link['href']
    vars = href.split("CodBuq=")
    #If there is more than 1 element in vars that means we have found the string on the split
    if vars.length > 1
      aux = vars[1].split("&")
      if aux.length > 1
        codShip = aux[0].strip;
        count += 1;
        output_file.puts([nameShip,codShip].join(","))
      else
        $log_file.puts("#We have not found '&' after 'CodBuq=': #{aux}")
        next
      end
    else
      $log_file.puts("#We have not found 'CodBuq=' on the href: #{href}")
      next  
    end
  end
  puts "We have found #{count} ships"
else
  $log_file.puts("#{INPUT_FILES_SUBDIR}/#{INITIAL_HTML}: We have not found any links on the page")
end