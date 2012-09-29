require 'outdent'

module CSVPort

  module Templates

    class << self

      attr_reader :build
      attr_reader :config
      attr_reader :db_connection
      attr_reader :error_log

    end

      @config = <<-CONFIG.outdent
        require 'json'
        #require 'pry'

        DB_NAME = "TODO"
        DB_USERNAME = "TODO"
        DB_PASSWORD = "TODO"
        DB_ENCODING = "TODO"

        PORTING_LIBRARY = "!!NAME!!"

        SOURCE_DATA_FILENAMES = [
          TODO
        ]
        HELPER_DATA_FILENAMES = [
          TODO
        ]
        ERROR_LOG_FILENAMES = ['error_log.json']

        DATA_DIRECTORY = File.expand_path("../data", "__FILE__")
        EXTERNAL_SOURCE_DATA_DIRECTORY = "TODO"
        SOURCE_DATA_DIRECTORY = File.expand_path('source', DATA_DIRECTORY)
        HELPER_DATA_DIRECTORY = File.expand_path('helper', DATA_DIRECTORY)
        ERROR_LOG_DIRECTORY = DATA_DIRECTORY

        SOURCE_DATA_HASH, HELPER_DATA_HASH, ERROR_LOG_HASH = ['SOURCE_DATA', 'HELPER_DATA', 'ERROR_LOG'].map do |data_type|
          filenames = eval(data_type + "_FILENAMES")
          directory = eval(data_type + "_DIRECTORY")
          hash = Hash [
            filenames.map do |filename|
              extension = File.extname(filename)
              [filename.chomp(extension).to_sym, {filename: filename, filetype: extension.delete('.'), path: File.expand_path(filename, directory)}]
            end  
          ]
        end

        #PATH_HASH = mary_data_hash.merge(helper_data_hash).merge(error_data_hash).merge(error_by_spreadsheet_hash)  # .merge(count_data_hash)
      CONFIG

      @db_connection = "DB = Sequel.mysql2(DB_NAME, user: DB_USERNAME, password: DB_PASSWORD, encoding: DB_ENCODING)"

      @error_log = "[]"

      @build = <<-BUILD.outdent
        #!/usr/bin/env ruby

        $LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

        require 'csv_port/builder'
        require 'methadone'

        include Methadone::Main

        main do
          path = File.expand_path('../'..', '__FILE__')
          builder = Builder.new(path, options)
          Builder.build
        end

        on("-e", "--empty", "Empty the database")
        on("-u", "--update", "Update the database")

        description "Builds the database from source files"
      BUILD
  end
end
