# encoding: utf-8
require 'fileutils'
require 'csv'
require 'mysql'

LOG_SUBDIR = '../logs'
INPUT_FILES_SUBDIR = '../updateDim'
FileUtils.makedirs(LOG_SUBDIR)

$log_file = File.open("#{LOG_SUBDIR}/updateDimDB.log", 'w')

#Connect to the mySQL database
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
  Dir.entries(INPUT_FILES_SUBDIR).select{|f| f.match(/.*_UPDATE\.txt/)}.each do |doc|
    puts "Reading #{doc}"
    vars=doc.split('_UPDATE.txt')
    table = vars[0]
    query = "SELECT MAX(id) FROM #{table}"
    results = $db.query query
    max_id = 0
    if results.num_rows > 0
      results.each do |row|
        max_id = row[0] ? Integer(row[0]) : 0
      end
      results.free
    end
    id = max_id
    statement = "INSERT INTO #{table} VALUES (?, ?)"
    if table.eql?("DIM_COUNTRY")
      statement = "INSERT INTO #{table} VALUES (?, ?, ?)"
    elsif table.eql?("DIM_PLACE")
      statement = "INSERT INTO #{table} VALUES (?, ?, ?)"
    end
    insert_statement = $db.prepare statement
    count = 0
    File.open("#{INPUT_FILES_SUBDIR}/#{doc}").each do |line|
      value = line.strip
      id += 1
      if table.eql?("DIM_COUNTRY") || table.eql?("DIM_PLACE")
        insert_statement.execute id,$db.escape_string(value),1
      else
        insert_statement.execute id,$db.escape_string(value)
      end
      count +=1
    end
    puts "We have processed the information of #{count} rows in table: #{table}"
    insert_statement.close
  end
ensure
  $db.close
end

#Once processed we delete the input folder for the next update to be clean
FileUtils.remove_dir("#{INPUT_FILES_SUBDIR}", force = false)
