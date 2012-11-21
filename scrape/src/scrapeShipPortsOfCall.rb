# encoding: utf-8
require 'fileutils'
require 'open-uri'
require 'csv'


AUX_URL_COOKIE = "http://gis.portel.es/aplicaciones/gisweb/giswebport/frames.asp?AutPor=26"
#BASE_LIST_URL = 'http://gis.portel.es/aplicaciones/gisweb/giswebport/mapas/datosBuq.asp?'
BASE_LIST_URL = 'http://gis.portel.es/aplicaciones/gisweb/giswebport/historicos/getForm1.asp?'
FECINI = 'FecIni='
FECFIN = 'FecFin=31/12/2012'

LOG_SUBDIR = '../logs'
INPUT_FILES_SUBDIR = '../txt'
OUTPUT_FILES_SUBDIR = '../html_stops'
INPUT_FILE = 'shipList.txt'
FileUtils.makedirs(LOG_SUBDIR)
FileUtils.makedirs(OUTPUT_FILES_SUBDIR)

$log_file = File.open("#{LOG_SUBDIR}/scrapeShipPortsOfCall.log", 'w')

#First we obtain the session cookie needed for the scraping
begin
  aux = open(AUX_URL_COOKIE)
  cookie =  aux.meta['set-cookie'].split('; ',2)[0]
rescue OpenURI::HTTPError => the_error
  # the_error.message is the numeric code and text in a string
  $log_file.puts("#{AUX_URL_COOKIE}: Got a bad status code #{the_error.message}")
end

Dir.entries(INPUT_FILES_SUBDIR).select{|f| f.match(/.*_shipList\.txt/)}.each do |doc|
  auxDate = doc.split("_shipList.txt")[0]
  dateItems = auxDate.split("_")
  selDate = "#{dateItems[2]}/#{dateItems[1]}/#{dateItems[0]}"
  puts selDate
  CSV.foreach("#{INPUT_FILES_SUBDIR}/#{doc}") do |row|
    shipName, code = row
    shipCode = URI::encode(code)
    url = "#{BASE_LIST_URL}CodBuq=#{shipCode}&#{FECINI}#{selDate}&#{FECFIN}"
    puts url
    begin
      page = open(url,"Cookie" => cookie)
      # create a new file into to which we copy the webpage contents
      # and then write the contents of the downloaded page (with the readlines method)
      #to this new file on our hard drive
      enc_code = code.gsub(/\//,"_");
      output_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{enc_code}_movs.html", 'w')
      page.readlines.each do |line|
        output_file.write(line.gsub!(/\r\n?/, "\n"))
      end
      puts "Copied page"
      # wait 2 seconds before getting the next page, to not overburden the website.
      sleep 2
    rescue OpenURI::HTTPError => the_error
      $log_file.puts("#{url}: Got a bad status code #{the_error.message}")
    end
  end
end