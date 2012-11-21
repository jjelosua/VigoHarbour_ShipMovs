# encoding: utf-8
require 'fileutils'
require 'csv'
require 'mysql'

#Patch to make mysql 2.8 utf8 friendly
class Mysql::Result
  def encode(value, encoding = "utf-8")
    String === value ? value.force_encoding(encoding) : value
  end
  
  def each_utf8(&block)
    each_orig do |row|
      yield row.map {|col| encode(col) }
    end
  end
  alias each_orig each
  alias each each_utf8

  def each_hash_utf8(&block)
    each_hash_orig do |row|
      row.each {|k, v| row[k] = encode(v) }
      yield(row)
    end
  end
  alias each_hash_orig each_hash
  alias each_hash each_hash_utf8
end

def load_db_dim_arrays()
  @dbTables_hash.each_key do |key|
    array = @dbTables_hash[key]
    load_db_array(key,array)
  end
end

def load_db_array (table,array)
  @db_dim_hash[array] = {}
  $db.query("SET NAMES utf8")
  results = $db.query "SELECT * FROM #{table}"
  if results.num_rows > 0
    results.each do |row|
      id, value = row
      @db_dim_hash[array][value] = Integer(id)
    end
    results.free
  end
end

def removeDuplicateValues()
  @dim_hash.each_key do |key|
    aux = @dim_hash[key].uniq
    @dim_hash[key] = aux
  end
end

def sortValues()
  @dim_hash.each_key do |key|
    aux = @dim_hash[key].sort
    @dim_hash[key] = aux
  end
end

def process_exceptions(str,hash)
  nStr = hash[str]
  if nStr
    return nStr
  else
    return str
  end
end

def formatDate(str)
  #Output format YYYY-MM-DD HH:MM:SS
  if str.length >0
    aux = str.split(" ")
    d = aux[0]
    t = aux[1]
    aux = d.split("/")
    t += ":00"
    fDate = "#{aux[2]}-#{aux[1]}-#{aux[0]} #{t}"
    return fDate
  else
    return "0000-00-00 00:00:00"
  end  
end

LOG_SUBDIR = '../logs'
INPUT_FILES_SUBDIR = '../txt'
SHIP_INPUT_FILE = 'shipData.csv'
DOCK_INPUT_FILE = 'dockData.csv'
OPER_INPUT_FILE = 'operData.csv'
SHIP_OUTPUT_FILE = 'DAT_SHIP_UPDATE.txt'
DOCK_OUTPUT_FILE = 'DAT_DOCK_UPDATE.txt'
OPER_OUTPUT_FILE = 'DAT_OPER_UPDATE.txt'
OUTPUT_FILES_SUBDIR = '../updateData'
FileUtils.makedirs(LOG_SUBDIR)
FileUtils.makedirs(OUTPUT_FILES_SUBDIR)
                  
@dbTables_hash = {"DIM_SHIPID"=>"dbShipId",
                  "DIM_DOCKID"=>"dbDockId",
                  "DIM_SHIPTYPE" => "dbShipType",
                  "DIM_COUNTRY" => "dbCountry",
                  "DIM_PLACE"=>"dbPlace",
                  "DIM_CONSIGNEE" => "dbConsignee",
                  "DIM_LONGSHORE"=>"dbLongshore",
                  "DIM_MERCHANDISE"=>"dbMerchandise",
                  "DIM_OPERTYPE"=>"dbOperType"}

#We acummulate the known exceptions detected on the dimmension treatment
#Country exceptions
@country_excep = {"ESPA\\A"=>"ESPAÑA",
                  "COTE D'IVOIRE"=>"COSTA DE MARFIL"}

#Place exceptions
@place_excep = {"A CORU\\A"=>"A CORUÑA",
                "CARI\\O"=>"CARIÑO",
                "MOA\\A"=>"MOAÑA",
                "LES SABLES D'OLONNE"=>"LES SABLES D\\'OLONNE"}

#shipType exceptions
@shipType_excep = {""=>"DESCONOCIDO"}

#consignee exceptions
@consignee_excep = {""=>"DESCONOCIDO"}

#operType exceptions
@operType_excep = {""=>"DESCONOCIDO"}

#longshore exceptions
@longshore_excep = {""=>"DESCONOCIDO",
                    "LINEAS MARITIMAS ESPA\\OLAS S.A"=>"LINEAS MARITIMAS ESPAÑOLAS S.A"}


#Merchandise exceptions
@merchandise_excep = {"FRUTA REFRIGUERADA"=>"FRUTA REFRIGERADA",
                      "SIDRURGICOS"=>"SIDERURGICOS"}
                  
@db_dim_hash = Hash.new {|h,k| h[k] = {} }

$log_file = File.open("#{LOG_SUBDIR}/extractDataFiles.log", 'w')

#DB connection
begin
  $db = Mysql.init
  $db.options(Mysql::SET_CHARSET_NAME, 'utf8')
  $db.real_connect('localhost','enrique', '', 'APVigo_ShipMovs')
  $db.query("SET NAMES utf8")
rescue Mysql::Error
  $log_file.puts("#We could not connect with the DB")
  exit 1
end

begin
  #Load the existing db dimension tables
  load_db_dim_arrays()

  #get the last id on the ship data table
  query = "SELECT MAX(id) FROM DAT_SHIP"
  results = $db.query query
  $ship_max_id = 0
  if results.num_rows > 0
    results.each do |row|
      $ship_max_id = Integer(row[0]) if row[0]
    end
    results.free
  end
  
  #get the last id on the ship data table
  query = "SELECT MAX(id) FROM DAT_DOCK"
  results = $db.query query
  $dock_max_id = 0
  if results.num_rows > 0
    results.each do |row|
      $dock_max_id = Integer(row[0]) if row[0]
    end
    results.free
  end
  
  #get the last id on the ship data table
  query = "SELECT MAX(id) FROM DAT_OPER"
  results = $db.query query
  $oper_max_id = 0
  if results.num_rows > 0
    results.each do |row|
      $oper_max_id = Integer(row[0]) if row[0]
    end
    results.free
  end
ensure
  $db.close
end

excep=false
#process the ship file
output_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{SHIP_OUTPUT_FILE}", 'w')
CSV.foreach("#{INPUT_FILES_SUBDIR}/#{SHIP_INPUT_FILE}", :quote_char => '"', :col_sep =>'|', :row_sep =>:auto) do |row|
    shipCode,shipName,shipLength,shipWidth,shipDraught,
    shipGrossTonnage,shipType,shipFlag,shipCode2,shipLLoydsId = row
    #obtain shipId
    idx = @db_dim_hash["dbShipId"][shipCode]
    if idx
      #Go to the next row if we have already this ship on the DB
      if idx <= $ship_max_id
        next
      end
      shipId = idx
      #Normalize known exceptions
      norm_sType = process_exceptions(shipType,@shipType_excep)
      norm_country = process_exceptions(shipFlag,@country_excep)
      #obtain shipTypeId
      idx = @db_dim_hash["dbShipType"][norm_sType]
      if idx
        shipTypeId = idx
      else
        $log_file.puts("#We have not found shipType: #{norm_sType} in the DB")
        excep = true
      end
      #obtain shipFlagId
      idx = @db_dim_hash["dbCountry"][norm_country]
      if idx
        shipFlagId = idx
      else
        $log_file.puts("#We have not found country: #{norm_country} in the DB")
        excep = true
      end
      #write row to output file
      output_file.puts([shipId,shipName,shipLength,shipWidth,shipDraught,
                        shipGrossTonnage,shipTypeId,shipFlagId,shipCode2,shipLLoydsId].join("|"))
    else
      $log_file.puts("#We have not found shipCode: #{shipCode} in the DB")
      excep = true
    end
end
output_file.close
puts "#{INPUT_FILES_SUBDIR}/#{SHIP_INPUT_FILE}: processed"
#If we have detected anomalies we stop the process so we can review the logs and fix the error.
if excep
  exit 1
end

#process the docking file
output_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{DOCK_OUTPUT_FILE}", 'w')
CSV.foreach("#{INPUT_FILES_SUBDIR}/#{DOCK_INPUT_FILE}", :quote_char => '"', :col_sep =>'|', :row_sep =>:auto) do |row|
    shipCode,dockCode,stop,bollards,quay,
    arrival,departure,consignee,origin,destination = row
    #obtain dockId
    idx = @db_dim_hash["dbDockId"][dockCode]
    if idx
      #Go to the next row if we have already this dock on the DB
      if idx <= $dock_max_id
        next
      end
      dockId = idx
      
      #process the origin field
      nOrigCountry = "" 
      nOrigPlace = ""
      if origin
        #looking from the end find the first opening parenthesis
        bef, mat, aft = origin.rpartition("(")
        if aft.length > 0
          #We remove the closing parenthesis
          country = aft.split(")")[0].strip
          nOrigCountry = process_exceptions(country,@country_excep)
        end
        #looking from the beginning find the first opening parenthesis
        bef, mat, aft = origin.partition("(")
        if bef.length > 0
          #We remove the additional spaces if needed
          place = bef.strip
          nOrigPlace = process_exceptions(place,@place_excep)
        end
      end
      #obtain origCountryId
      idx = @db_dim_hash["dbCountry"][nOrigCountry]
      if idx
        origCountryId = idx
      else
        $log_file.puts("#We have not found country: #{nOrigCountry} in the DB")
        excep = true
      end
      #obtain origPlaceId
      idx = @db_dim_hash["dbPlace"][nOrigPlace]
      if idx
        origPlaceId = idx
      else
        $log_file.puts("#We have not found place: #{nOrigPlace} in the DB")
        excep = true
      end
      
      #process the destination field
      nDestCountry = "" 
      nDestPlace = ""
      if destination
        #looking from the end find the first opening parenthesis
        bef, mat, aft = destination.rpartition("(")
        if aft.length > 0
          #We remove the closing parenthesis
          country = aft.split(")")[0].strip
          nDestCountry = process_exceptions(country,@country_excep)
        end
        #looking from the beginning find the first opening parenthesis
        bef, mat, aft = destination.partition("(")
        if bef.length > 0
          #We remove the additional spaces if needed
          place = bef.strip
          nDestPlace = process_exceptions(place,@place_excep)
        end
      end
      #obtain destCountryId
      idx = @db_dim_hash["dbCountry"][nDestCountry]
      if idx
        destCountryId = idx
      else
        $log_file.puts("#We have not found country: #{nDestCountry} in the DB")
        excep = true
      end
      #obtain destPlaceId
      idx = @db_dim_hash["dbPlace"][nDestPlace]
      if idx
        destPlaceId = idx
      else
        $log_file.puts("#We have not found place: #{nDestPlace} in the DB")
        excep = true
      end
      
      #obtain consignee
      nConsignee = process_exceptions(consignee,@consignee_excep)
      idx = @db_dim_hash["dbConsignee"][nConsignee]
      if idx
        consigneeId = idx
      else
        $log_file.puts("#We have not found consignee: #{nConsignee} in the DB")
        excep = true
      end
      
      #obtain shipId
      idx = @db_dim_hash["dbShipId"][shipCode]
      if idx
        shipId = idx
      else
        $log_file.puts("#We have not found shipCode: #{shipCode} in the DB")
        excep = true
      end
      fArrival = formatDate(arrival)
      fDeparture = formatDate(departure)
      #write row to output file
      output_file.puts([dockId,shipId,stop,bollards,quay,fArrival,fDeparture,
                        consigneeId,origPlaceId,origCountryId,destPlaceId,destCountryId].join("|"))
    else
      $log_file.puts("#We have not found dockCode: #{dockCode} in the DB")
      excep = true
    end
    
end
output_file.close
puts "#{INPUT_FILES_SUBDIR}/#{DOCK_INPUT_FILE}: processed"
if excep
  exit 1
end

#process the operations file
output_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{OPER_OUTPUT_FILE}", 'w')
operId = $oper_max_id
CSV.foreach("#{INPUT_FILES_SUBDIR}/#{OPER_INPUT_FILE}", :quote_char => '"', :col_sep =>'|', :row_sep =>:auto) do |row|
    shipCode,dockCode,operSec,operType,
    operDesc,tons,merchandise,longShore = row
    #obtain dockId
    idx = @db_dim_hash["dbDockId"][dockCode]
    if idx
      #Go to the next row if we have already this dock on the DB
      if idx <= $dock_max_id
        next
      end
      dockId = idx
      
      #obtain shipId
      idx = @db_dim_hash["dbShipId"][shipCode]
      if idx
        shipId = idx
      else
        $log_file.puts("#We have not found shipCode: #{shipCode} in the DB")
        excep = true
      end
      
      #obtain operTypeId
      nOperType = process_exceptions(operType,@operType_excep)
      idx = @db_dim_hash["dbOperType"][nOperType]
      if idx
        operTypeId = idx
      else
        $log_file.puts("#We have not found operType: #{nOperType} in the DB")
        excep = true
      end
      
      #obtain merchandiseId
      nMerchandise = process_exceptions(merchandise,@merchandise_excep)
      idx = @db_dim_hash["dbMerchandise"][nMerchandise]
      if idx
        merchandiseId = idx
      else
        $log_file.puts("#We have not found merchandise: #{nMerchandise} in the DB")
        excep = true
      end
      
      #obtain longshoreId
      nLongshore = process_exceptions(longShore,@longshore_excep)
      idx = @db_dim_hash["dbLongshore"][nLongshore]
      if idx
        longshoreId = idx
      else
        $log_file.puts("#We have not found longshore: #{nLongshore} in the DB")
        excep = true
      end
      operId += 1
      #write row to output file
      output_file.puts([operId,shipId,dockId,operSec,operTypeId,operDesc,tons,
                        merchandiseId,longshoreId].join("|"))
    else
      $log_file.puts("#We have not found dockCode: #{dockCode} in the DB")
    end
end
output_file.close
puts "#{INPUT_FILES_SUBDIR}/#{OPER_INPUT_FILE}: processed"
