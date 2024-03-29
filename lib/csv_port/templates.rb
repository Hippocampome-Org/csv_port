require 'outdent'

module CSVPort

  module Templates

    class << self

      attr_reader :build
      attr_reader :config
      attr_reader :db_connection
      attr_reader :error_log
      attr_reader :lib_base

    end

      @build = <<-BUILD.outdent
          #!/usr/bin/env ruby

          $LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

          require 'csv_port/builder'
          require 'methadone'

          include Methadone::Main
          include Methadone::CLILogging

          main do
            path = File.expand_path('..', '__FILE__')
            builder = CSVPort::Builder.new(path, options)
            builder.build
          end

          on("-c", "--clear_errors", "Clear error logs")
          on("-e", "--empty_database", "Empty the database")
          on("-u", "--update_source_files", "Update source files")

          description "Builds the database from source files"

          go!
        BUILD


      @config = <<-CONFIG.outdent
        require 'csv_port'
        require 'json'
        #require 'pry'

        DB_NAME = "TODO"
        DB_USERNAME = "TODO"
        DB_PASSWORD = "TODO"
        DB_ENCODING = "TODO"

        PORTING_LIBRARY = "!!NAME!!"

        SOURCE_DATA = [
          {
            filename: TODO,
            cleaner: !!NAME!!::TODO,
            record_validator: TODO,
            record_loader: TODO
          },
          ... ADD OTHER ENTRIES HERE
        ]

        HELPER_DATA = [
          TODO (should be an array of filenames)
        ]

        ERROR_DATA = [
          'error_log.json'
        ]

        DATA_DIRECTORY = File.expand_path("../data", "__FILE__")
        EXTERNAL_SOURCE_DATA_DIRECTORY = "TODO"
        SOURCE_DATA_DIRECTORY = File.expand_path('source', DATA_DIRECTORY)
        HELPER_DATA_DIRECTORY = File.expand_path('helper', DATA_DIRECTORY)
        ERROR_DATA_DIRECTORY = DATA_DIRECTORY
      CONFIG


      @db_connection = "DB = Sequel.mysql2(DB_NAME, user: DB_USERNAME, password: DB_PASSWORD, encoding: DB_ENCODING)"


      @error_log = "[]"

      
      @lib_base = <<-LIB_BASE.outdent
        !!REQUIRE!!

        module !!NAME!!

        end
      LIB_BASE

      @models = "### DB MODELS HERE ###"

  end
end
