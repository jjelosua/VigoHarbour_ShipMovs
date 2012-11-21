# encoding: utf-8
require 'open-uri'
require 'fileutils'
require 'nokogiri'

LOG_SUBDIR = '../logs'
INPUT_FILES_SUBDIR = '../html_stops'
OUTPUT_FILES_SUBDIR = '../txt'
FileUtils.makedirs(LOG_SUBDIR)
FileUtils.makedirs(OUTPUT_FILES_SUBDIR)

$log_file = File.open("#{LOG_SUBDIR}/processShipPortsOfCall.log", 'w')
output_file = File.open("#{OUTPUT_FILES_SUBDIR}/shipPortsOfCall.txt", 'w')
count = 0
Dir.entries(INPUT_FILES_SUBDIR).select{|f| f.match(/.*_movs\.html/)}.each do |doc|
  puts "Reading #{doc}"
  vars=doc.split('_movs.html')
  shipCode=vars[0]
  begin
    page=Nokogiri::HTML(open("#{INPUT_FILES_SUBDIR}/#{doc}"))
  rescue OpenURI::HTTPError => the_error
    # the_error.message is the numeric code and text in a string
    $log_file.puts("#{INPUT_FILES_SUBDIR}/#{doc}: Got a bad status code #{the_error.message}")
  end
  links = page.css('a')
  if links.length > 0 
    codCall,authHar,subHar,type = nil
    prev_href = nil
    links[0..-1].each do |link|
      href = link['href']
      if href.eql? prev_href
        next
      end
      vars = href.split("'")
      codDock = vars[1]
      authHar = vars[3]
      subHar = vars[5]
      type = vars[7]
      #puts "codDock: #{codDock} authHar: #{authHar} subHar: #{subHar} type: #{type}" 
      output_file.puts([shipCode,codDock,authHar,subHar,type].join(","))
      count += 1
      prev_href = href
    end
  else
    $log_file.puts("#{INPUT_FILES_SUBDIR}/#{doc}: No links found")
  end 
end
puts "We have found #{count} dockings"
output_file.close