#!/usr/bin/env ruby
# ST Mackesey
# Run this script to create and populate the hippocampome database in MySQL.  Make sure that 
# 'hippocampome.sql', 'hippo.rb', 'source.csv', and 'hc_class.csv' are in the same directory
# as the script.  Before executing, the script will prompt for a username and password for MySQL.
# Note that this script requires Ruby 1.9.3 and the mysql2 and sequel gems.

require 'csv'
require 'json'
require 'pry'

module CSVPort

  class Builder

    class << self
      attr_accessor :auxilary_loader_methods
      attr_accessor :auxilary_writer_methods
    end

    # Should all return arrays of hashes
    @auxilary_loader_methods = {
      'csv' => lambda { |filepath| CSV.read(filepath, headers: true).map{ |row| row.to_hash }},
      'json' => lambda { |filepath| JSON.load(File.new(filepath, 'r')) },
      #'yaml' => { class: YAML, method: :load },
      #'yml' => { class: YAML, method: :load },
    }

    @auxilary_writer_methods = {
      'csv' => lambda { |filepath, data| File.write(filepath, data.to_csv) },
      'json' => lambda { |filepath, data| File.write(filepath, JSON.pretty_generate(data)) },
    }

    AuxilaryFile = Struct.new(:filename, :filetype, :filepath, :data)

    attr_accessor :error_data_hash
    attr_accessor :helper_data_hash

    def initialize(path, options={})
      @path = path
      @options = options
      @project_name ||= File.basename(path) 
    end

    def build
      $builder = self
      set_up_environment
      initialize_helper_data
      initialize_error_data
      clear_errors if @options[:clear_errors]
      open_database_connection
      empty_database if @options[:empty_database]  # will erase current database of name 'hippocampome'
      add_views if @options[:add_views]
      load_models
      load_porting_library
      initialize_source_metadata
      update_source_files if @options[:update_source_files]  # copies and converts all source data to utf-8
      @source_data_hash.values.each { |source_file| load_source_file(source_file) }
    ensure
      update_helper_data
      write_error_logs
    end


    ##### HELPER METHODS

    def set_up_environment
      require File.expand_path('config', @path)
    end

    def clear_errors
      ERROR_DATA.map do |filename|
        File.write(File.expand_path(filename, ERROR_DATA_DIRECTORY), "[]")
      end
    end

    def open_database_connection
      require File.expand_path('db/db_connection', @path)
    end

    def load_models
      require File.expand_path('db/models', @path)  # stored in the db directory added above
    end

    def load_porting_library
      require File.expand_path("lib/#{PORTING_LIBRARY[:filename]}", @path)
    end

    def initialize_source_metadata
      source_data_pairs = SOURCE_DATA.map do |source|
        key = source[:target]
          data = eval(PORTING_LIBRARY[:module_name])::PORT_DATA[key]
          data.update({ filename: source[:filename]})
          value = SourceFile.new(data, SOURCE_DATA_DIRECTORY)
          [key, value]
        end
      @source_data_hash = Hash[ source_data_pairs ]
    end

    def update_source_files
      filenames = @source_data_hash.map { |symbol, source_file| source_file.filename }
      CSVPort.build_directory(EXTERNAL_SOURCE_DATA_DIRECTORY, SOURCE_DATA_DIRECTORY, filenames, encoding: "utf-8")
    end

    def empty_database
      temp_filename = "#{DB_NAME}_schema_tmp.sql"
      `mysqldump -d -u#{DB_USERNAME} -p#{DB_PASSWORD} --add-drop-table #{DB_NAME} > #{temp_filename}`  # dump schema with no data
      `mysql -u#{DB_USERNAME} -p#{DB_PASSWORD} #{DB_NAME} < #{temp_filename}`  # load schema
      FileUtils.rm(temp_filename)
    end

    def add_views
      view_filename = @project_name + "_views.sql"
      view_filepath = File.expand_path(view_filename, @path)
      `mysql -u#{DB_USERNAME} -p#{DB_PASSWORD} #{DB_NAME} < #{view_filepath}`  # load schema
    end

    def initialize_helper_data
      helper_data_pairs = HELPER_DATA.map do |filename|
        key = filename.chomp(File.extname(filename)).to_sym
        value = create_auxilary_file(filename, HELPER_DATA_DIRECTORY)
        [key, value]
      end
      @helper_data_hash = Hash[ helper_data_pairs ]
    end

    def initialize_error_data
      error_data_pairs = ERROR_DATA.map do |filename|
        key = filename.chomp(File.extname(filename)).to_sym
        value = create_auxilary_file(filename, ERROR_DATA_DIRECTORY)
        [key, value]
      end
      @error_data_hash = Hash[ error_data_pairs ]
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
      @helper_data_hash.each do |key, file|
        writer_method = self.class.auxilary_writer_methods[file.filetype]
        writer_method.call(file.filepath, file.data)
      end
    end

    def write_error_logs
      @error_data_hash.each do |key, file|
        writer_method = self.class.auxilary_writer_methods[file.filetype]
        writer_method.call(file.filepath, file.data)
      end
    end

  end
  
end
