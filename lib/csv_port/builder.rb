#!/usr/bin/env ruby
# ST Mackesey
# Run this script to create and populate the hippocampome database in MySQL.  Make sure that 
# 'hippocampome.sql', 'hippo.rb', 'source.csv', and 'hc_class.csv' are in the same directory
# as the script.  Before executing, the script will prompt for a username and password for MySQL.
# Note that this script requires Ruby 1.9.3 and the mysql2 and sequel gems.

require 'csv'
require 'json'
require 'pry'

require 'csv_port'

module CSVPort

  class Builder

    class << self
      attr_accessor :auxilary_loader_methods
    end

    # Should all return arrays of hashes
    @auxilary_loader_methods = {
      'csv' => lambda { |filepath| CSV.read(filepath, headers: true).map{ |row| row.to_hash }},
      'json' => lambda { |filepath| JSON.load(File.new(filepath, 'r')) },
      #'yaml' => { class: YAML, method: :load },
      #'yml' => { class: YAML, method: :load },
    }

    AuxilaryFile = Struct.new(:filename, :filetype, :filepath, :data)

    def initialize(path, project_name=nil, options={})
      @path = path
      @options = options
      @project_name ||= File.basename(path) 
    end

    def build
      set_up_environment
      open_database_connection
      load_models
      load_porting_library
      initialize_source_metadata
      update_source_files if @options[:update_source_files]  # copies and converts all source data to utf-8
      empty_database if @options[:empty_database]  # will erase current database of name 'hippocampome'
      initialize_helper_data
      initialize_error_data
      begin
        @source_data_hash.values.each { |source_file| load_source_file(source_file) }
      rescue StandardError => e
        binding.pry
      ensure
        update_helper_data
        write_error_logs
      end
    end


    ##### HELPER METHODS

    def set_up_environment
      require File.expand_path('config', @path)
    end

    def open_database_connection
      require File.expand_path('db/db_connection', @path)
    end

    def load_models
      require File.expand_path('db/models', @path)  # stored in the db directory added above
    end

    def load_porting_library
      require File.expand_path("lib/#{PORTING_LIBRARY}", @path)
    end

    def initialize_source_metadata
      source_data_pairs = SOURCE_DATA.map do |source|
          key = source[:filename].chomp(File.extname(source[:filename])) 
          value = SourceFile.new(source, SOURCE_DATA_DIRECTORY)
          [key, value]
        end
      @source_data_hash = Hash[ source_data_pairs ]
    end

    def update_csvs
      filenames = @source_data_hash.map { |symbol, source_file| source_file.filename }
      CSVPort.build_directory(EXTERNAL_SOURCE_DATA_DIRECTORY, SOURCE_DATA_DIRECTORY, filenames, encoding: "utf-8")
    end

    def empty_database
      temp_filename = "#{DB_NAME}_schema_tmp.sql"
      `mysqldump -d -u#{DB_USERNAME} -p#{DB_PASSWORD} --add-drop-table #{DB_NAME} > #{temp_filename}`  # dump schema with no data
      `mysql -u#{DB_USERNAME} -p#{DB_PASSWORD} #{DB_NAME} < #{temp_filename}`  # load schema
      FileUtils.rm(temp_filename)
    end

    def initialize_helper_data
      helper_data_pairs = HELPER_DATA.map do |filename|
        key = filename.chomp(File.extname(filename)).to_sym
        value = create_auxilary_file(filename, HELPER_DATA_DIRECTORY)
        [key, value]
      end
      HELPER_DATA_HASH = Hash[ helper_data_pairs ]
    end

    def initialize_error_data
      error_data_pairs = ERROR_DATA.map do |filename|
        key = filename.chomp(File.extname(filename)).to_sym
        value = create_auxilary_file(filename, ERROR_DATA_DIRECTORY)
        [key, value]
      end
      ERROR_DATA_HASH = Hash[ error_data_pairs ]
    end

        def create_auxilary_file(filename, directory)
          extension = File.extname(filename)
          filetype= extension.delete('.')
          loader_method = self.class.auxilary_loader_methods[filetype]
          filepath = File.expand_path(filename, directory)
          data = loader_method.call(filepath)
          AuxilaryFile.new(filename, filetype, filepath, data)
        end

    def load_source_file(source_file)
      source_file.load
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
