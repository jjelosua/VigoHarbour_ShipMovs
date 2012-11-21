# encoding: utf-8
require 'fileutils'
require 'csv'
require 'mysql'

LOG_SUBDIR = '../logs'
INPUT_FILES_SUBDIR = '../updateData'
FileUtils.makedirs(LOG_SUBDIR)

$log_file = File.open("#{LOG_SUBDIR}/updateDataDB.log", 'w')

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
    statement = "INSERT INTO #{table} VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
    if table.eql?("DAT_SHIP")
      statement = "INSERT INTO #{table} VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    elsif table.eql?("DAT_DOCK")
      statement = "INSERT INTO #{table} VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    end
    insert_statement = $db.prepare statement
    count = 0
    CSV.foreach("#{INPUT_FILES_SUBDIR}/#{doc}", :col_sep =>'|', :row_sep =>:auto) do |row|
      insert_statement.execute(*row)
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
