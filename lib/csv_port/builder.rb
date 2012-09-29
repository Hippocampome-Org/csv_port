#!/usr/bin/env ruby
# ST Mackesey
# Run this script to create and populate the hippocampome database in MySQL.  Make sure that 
# 'hippocampome.sql', 'hippo.rb', 'source.csv', and 'hc_class.csv' are in the same directory
# as the script.  Before executing, the script will prompt for a username and password for MySQL.
# Note that this script requires Ruby 1.9.3 and the mysql2 and sequel gems.


require 'csv_port'
#require 'optparse'
require 'pry'

module CSVPort

  class Builder

    def initialize(path, options={})
      @path = path
      @options = options
    end

    def build
      set_up_environment
      update_source_files if @options[:update_source_files]  # copies and converts all source data to utf-8
      empty_database if @options[:empty_database]  # will erase current database of name 'hippocampome'
      open_database_connection
      load_models
      load_porting_library
      initialize_helper_data
      initialize_error_log
      begin
        SOURCE_DATA_HASH.keys.each { |table| load_table(table) }
      ensure
        update_helper_data
        write_error_logs
      end
    end


    ##### HELPER METHODS

    def set_up_environment
      require File.expand_path('config', @path)
    end

    def update_csvs
      filenames = SOURCE_DATA_HASH.map { |symbol, hash| hash[:filename] }
      CSVPort.build_directory(EXTERNAL_SOURCE_DATA_DIRECTORY, SOURCE_DATA_DIRECTORY, filenames, encoding: "utf-8")
    end

    def empty_database
      temp_filename = "#{DB_NAME}_schema_tmp.sql"
      `mysqldump -d -u#{DB_USERNAME} -p#{DB_PASSWORD} --add-drop-table #{DB_NAME} > #{temp_filename}`  # dump schema with no data
      `mysql -u#{DB_USERNAME} -p#{DB_PASSWORD} #{DB_NAME} < #{temp_filename}`  # load schema
      FileUtils.rm(temp_filename)
    end

    def open_database_connection
      require File.expand_path('../../db/db_connection', @path)
    end

    def load_models
      require File.expand_path('../../db/models', @path)  # stored in the db directory added above
    end

    def load_porting_library
      require File.expand_path("../../lib/#{PORTING_LIBRARY}")
    end

    def initialize_helper_data
      HELPER_DATA_HASH.each do |symbol, hash|
        hash.update({ data: JSON.load(hash[:path]) })
      end
    end

    def initialize_error_log
      ERROR_LOG_HASH.each do |symbol, hash|
        hash.update({ data: [] })
      end
    end

    def load_table(table)
      $file = SOURCE_DATA_HASH[table][filename]
      table_class_str = table.to_s.split('_').map{ |word| word[0].upcase + word[1..-1] }.join('')
      print_str = table.to_s.gsub('_', ' ').upcase
      puts "---BUILDING #{print_str} TABLE......................"
      cleaned_table = clean_table(table, table_class_str)
      rows = cleaned_table.hash_rows
      rows.each_with_index do |row, i|
        $row = i + cleaned_table.row_transform
        load_row(table, table_class_str, row)
      end
      puts "----- #{print_str} TABLE BUILT......................"
    end

    def clean_table(table_class_str)
      cleaner_class = "Hippo::" + table_class_str + "CSVCleaner"
      command = cleaner_class + ".new(" + SOURCE_DATA_HASH[table][path] +")"
      cleaned_table = eval(command)
    end

    def load_row(table, table_class_str, row)
      loader_class = table_class_str + "RowLoader"
      command = loader_class + ".new(row).load"
    rescue LoadingError => e
      e.log
    end

    def update_helper_data
      HELPER_DATA_HASH.each do |symbol, hash|
        File.write(hash[:path], JSON.pretty_generate(hash[:data]))
      end
    end

    def write_error_logs
      ERROR_LOG_HASH.each do |symbol, hash|
        File.write(hash[:path], JSON.pretty_generate(hash[:data]))
      end
    end

  end
  
end
