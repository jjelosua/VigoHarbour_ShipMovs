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
  begin
    @dbTables_hash.each_key do |key|
      array = @dbTables_hash[key]
      load_db_array(key,array)
    end
  ensure
    $db.close
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

def debugLengths()
  @dim_hash.each_key do |key|
    puts "#{key}: #{@dim_hash[key].length}"
  end
end

def writeOutputFiles()
  @dim_hash.each_key do |key|
    output_file = File.open("#{OUTPUT_FILES_SUBDIR}/#{@filenames_hash[key]}", 'w')
    @dim_hash[key].each{|item| output_file.puts(item)}
    output_file.close
  end
end

LOG_SUBDIR = '../logs'
INPUT_FILES_SUBDIR = '../txt'
SHIP_INPUT_FILE = 'shipData.csv'
DOCK_INPUT_FILE = 'dockData.csv'
OPER_INPUT_FILE = 'operData.csv'
OUTPUT_FILES_SUBDIR = '../updateDim'
FileUtils.makedirs(LOG_SUBDIR)
FileUtils.makedirs(OUTPUT_FILES_SUBDIR)

@filenames_hash = {"array_sCode"=>"DIM_SHIPID_UPDATE.txt",
                  "array_sType"=>"DIM_SHIPTYPE_UPDATE.txt",
                  "array_country" => "DIM_COUNTRY_UPDATE.txt",
                  "array_place" => "DIM_PLACE_UPDATE.txt",
                  "array_dCode"=>"DIM_DOCKID_UPDATE.txt",
                  "array_dConsignee" => "DIM_CONSIGNEE_UPDATE.txt",
                  "array_oType"=>"DIM_OPERTYPE_UPDATE.txt",
                  "array_oMerchandise"=>"DIM_MERCHANDISE_UPDATE.txt",
                  "array_oLongShore"=>"DIM_LONGSHORE_UPDATE.txt"}
                  
@dbTables_hash = {"DIM_SHIPID"=>"dbShipId",
                  "DIM_DOCKID"=>"dbDockId",
                  "DIM_SHIPTYPE" => "dbShipType",
                  "DIM_COUNTRY" => "dbCountry",
                  "DIM_PLACE"=>"dbPlace",
                  "DIM_CONSIGNEE" => "dbConsignee",
                  "DIM_LONGSHORE"=>"dbLongshore",
                  "DIM_MERCHANDISE"=>"dbMerchandise",
                  "DIM_OPERTYPE"=>"dbOperType"}
                  
@dim_hash = Hash.new {|h,k| h[k] = [] }
@db_dim_hash = Hash.new {|h,k| h[k] = {} }

$log_file = File.open("#{LOG_SUBDIR}/extractDimFiles.log", 'w')
begin
  $db = Mysql.init
  $db.options(Mysql::SET_CHARSET_NAME, 'utf8')
  $db.real_connect('localhost','enrique', '', 'APVigo_ShipMovs')
  $db.query("SET NAMES utf8")
rescue Mysql::Error
  $log_file.puts("#We could not connect with the DB")
  exit 1
end
#Load the existing db dimension tables
load_db_dim_arrays()

#process the ship file
CSV.foreach("#{INPUT_FILES_SUBDIR}/#{SHIP_INPUT_FILE}", :quote_char => '"', :col_sep =>'|', :row_sep =>:auto) do |row|
    shipCode,shipName,shipLength,shipWidth,shipDraught,
    shipGrossTonnage,shipType,shipFlag,shipCode2,shipLLoydsId = row
    if !(@db_dim_hash["dbShipId"].has_key?(shipCode))
      @dim_hash["array_sCode"].push(shipCode)
      if !(@db_dim_hash["dbShipType"].has_key?(shipType))
        @dim_hash["array_sType"].push(shipType) if shipType.length>0
      end
      if !(@db_dim_hash["dbCountry"].has_key?(shipFlag))
        @dim_hash["array_country"].push(shipFlag)
      end
    end
end
puts "#{INPUT_FILES_SUBDIR}/#{SHIP_INPUT_FILE}: processed"

#process the docking file
CSV.foreach("#{INPUT_FILES_SUBDIR}/#{DOCK_INPUT_FILE}", :quote_char => '"', :col_sep =>'|', :row_sep =>:auto) do |row|
    shipCode,dockCode,stop,bollards,quay,
    arrival,departure,consignee,origin,destination = row
    if !(@db_dim_hash["dbDockId"].has_key?(dockCode))
      @dim_hash["array_dCode"].push(dockCode)
      if !(@db_dim_hash["dbConsignee"].has_key?(consignee))
        @dim_hash["array_dConsignee"].push(consignee) if consignee.length>0
      end
      
      #process the origin field
      if origin
        #looking from the end find the first opening parenthesis
        bef, mat, aft = origin.rpartition("(")
        if aft.length > 0
          #We remove the closing parenthesis
          country = aft.split(")")[0].strip
          if !(@db_dim_hash["dbCountry"].has_key?(country))
            @dim_hash["array_country"].push(country)
          end
        else
          #log
        end
        #looking from the beginning find the first opening parenthesis
        bef, mat, aft = origin.partition("(")
        if bef.length > 0
          #We remove the additional spaces if needed
          place = bef.strip
          if !(@db_dim_hash["dbPlace"].has_key?(place))
            @dim_hash["array_place"].push(place)
          end
        else
          #log
        end
      else
        #log
      end
    
      #process the destination field
      if destination
        #looking from the end find the first opening parenthesis
        bef, mat, aft = destination.rpartition("(")
        if aft.length > 0
          #We remove the closing parenthesis
          country = aft.split(")")[0].strip
          if !(@db_dim_hash["dbCountry"].has_key?(country))
            @dim_hash["array_country"].push(country)
          end
        else
          #log
        end
        #looking from the beginning find the first opening parenthesis
        bef, mat, aft = destination.partition("(")
        if bef.length > 0
          #We remove the additional spaces if needed
          place = bef.strip
          if !(@db_dim_hash["dbPlace"].has_key?(place))
            @dim_hash["array_place"].push(place)
          end
        else
          #log
        end
      else
        #log
      end
    end #If include dockCode
end

puts "#{INPUT_FILES_SUBDIR}/#{DOCK_INPUT_FILE}: processed"

#process the operations file
CSV.foreach("#{INPUT_FILES_SUBDIR}/#{OPER_INPUT_FILE}", :quote_char => '"', :col_sep =>'|', :row_sep =>:auto) do |row|
    shipCode,dockCode,operSec,operType,
    operDesc,tons,merchandise,longShore = row
    if !(@db_dim_hash["dbDockId"].has_key?(dockCode))
      if !(@db_dim_hash["dbOperType"].has_key?(operType))
        @dim_hash["array_oType"].push(operType) if operType.length>0
      end
      if !(@db_dim_hash["dbMerchandise"].has_key?(merchandise))
        @dim_hash["array_oMerchandise"].push(merchandise) if merchandise.length>0
      end
      if !(@db_dim_hash["dbLongshore"].has_key?(longShore))
        @dim_hash["array_oLongShore"].push(longShore) if longShore.length>0
      end
    end #If include dockCode
end
puts "#{INPUT_FILES_SUBDIR}/#{OPER_INPUT_FILE}: processed"

removeDuplicateValues()
sortValues()
writeOutputFiles()