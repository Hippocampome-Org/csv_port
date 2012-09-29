module CSVPort

  module Templates

    attr_reader :config
    attr_reader :error_log

    class << self

      @config = <<-CONFIG
        require 'json'
        #require 'pry'

        DB_NAME = "TODO"
        DB_USERNAME = "TODO"
        DB_PASSWORD = "TODO"
        DB_ENCODING = "TODO"

        PORTING_LIBRARY = "!!NAME!!"

        SOURCE_DATA_FILENAMES = [TODO]
        HELPER_DATA_FILENAMES = [TODO]
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
        #HELPER_HASH = Hash[ HELPER_DATA_FILENAMES.zip(HELPER_DATA_FILENAMES.map { |key| JSON.parse(File.read(PATH_HASH[key]), symbolize_names: true) }) ]
        #ERROR_HASH = {}
      CONFIG

      @error_log = "[]"

    end
  end
end
