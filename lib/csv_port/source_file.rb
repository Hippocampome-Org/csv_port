module CSVPort

  class SourceFile

    attr_accessor :filename
    attr_accessor :cleaner
    attr_accessor :record_loader
    attr_accessor :record_validator
    attr_accessor :filepath
    attr_accessor :filetype

    def initialize(filename, cleaner, record_validator, record_loader, directory)
      @filename = filename
      @cleaner = cleaner
      @record_validator = record_validator
      @record_loader = record_loader
      @filepath = File.expand_path(filename, directory)
      @filetype = File.extname(filename).delete('.')
    end

    def load
      $file = source_file.filename
      puts "---LOADING #{source_file.filename}......................"
      cleaned_file = clean
      records = cleaned_file.hashes
      records.each_with_index do |record, i|
        $record = i + cleaned_file.record_transform
        load_record(record)
      end
      puts "----- #{source_file.filename} LOADED......................"
    end

    def load_record(record)
      @record_loader.new(row).load
    rescue LoadingError => e
      e.log
    end

    def clean
      @cleaner.new(@filepath, record_validator: @record_validator)
    end

  end

end
