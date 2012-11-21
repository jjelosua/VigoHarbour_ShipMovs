# encoding: utf-8
require 'open-uri'
require 'fileutils'
require 'nokogiri'
require 'csv'

class String
  # a helper function to turn all tabs, carriage returns, multiple spaces or nbsp into a regular space
  def astrip
    self.gsub(/([\s|\n|\t]){1,}/, ' ').strip
  end
end

LOG_SUBDIR = '../logs'
INPUT_FILES_SUBDIR = '../html_docks'
INDEX_FILE_SUBDIR = '../txt'
INDEX_FILE = 'shipPortsOfCall.txt'
OUTPUT_FILES_SUBDIR = '../csv'
SHIP_DATA_FILE_NAME = 'shipData.csv'
DOCK_DATA_FILE_NAME = 'dockData.csv'
OPER_DATA_FILE_NAME = 'operData.csv'
FileUtils.makedirs(LOG_SUBDIR)
FileUtils.makedirs(OUTPUT_FILES_SUBDIR)

$log_file = File.open("#{LOG_SUBDIR}/processShipDockingInfo.log", 'w')
sData_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{SHIP_DATA_FILE_NAME}", 'w')
dData_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{DOCK_DATA_FILE_NAME}", 'w')
oData_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{OPER_DATA_FILE_NAME}", 'w')

prev_shipCode = ''
count = 0
nbsp = Nokogiri::HTML("&nbsp;").text
CSV.foreach("#{INDEX_FILE_SUBDIR}/#{INDEX_FILE}") do |row|
    shipCode,codDock,authHar,subHar,type = row
    processShipData = (shipCode.eql? prev_shipCode) ? false : true
    page = open("#{INPUT_FILES_SUBDIR}/#{shipCode}_#{codDock}_dock.html")
    puts "#{INPUT_FILES_SUBDIR}/#{shipCode}_#{codDock}_dock.html"
    doc = Nokogiri::HTML(page)
    rowsData = doc.xpath('//table[1]//tr[2]//table//tr')
    rowsOper = doc.xpath('//table[1]//tr[3]//table//tr')
    processOperData = (rowsOper.length > 0) ? true : false
    dockData = "\"#{shipCode}\"|\"#{codDock}\""
    shipData = "\"#{shipCode}\""
    rowsData.each do |row|
        td = row.css('td')
        dockData << "|\"#{td[2].text.gsub(nbsp, ' ').astrip}\"" 
        shipData << "|\"#{td[5].text.gsub(nbsp, ' ').astrip}\""
    end
    if processShipData
        sData_file.puts(shipData) 
    end
    dData_file.puts(dockData)
    if processOperData
        idOper = 1
        rowsOper[2..-1].each do |rowOp|
            operData = "\"#{shipCode}\"|\"#{codDock}\"|\"#{idOper.to_s()}\""
            td = rowOp.css('td')
            td.each do |field|
                operData << "|\"#{field.text.gsub(nbsp, ' ').astrip}\""
            end
            oData_file.puts(operData)
            idOper += 1
        end
    else
      $log_file.puts("#{INPUT_FILES_SUBDIR}/#{shipCode}_#{codDock}_dock.html: No operations found")
    end
    page.close
    count += 1
    prev_shipCode = shipCode
end
puts "We have processed the information of #{count} dockings"
sData_file.close
dData_file.close
oData_file.close