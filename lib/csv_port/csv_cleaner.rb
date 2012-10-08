module CSVPort

  class CSVCleaner

    class << self
      attr_accessor :field_mapping
      attr_accessor :required_fields
    end

    attr_accessor :rows
    attr_accessor :row_transform 
    attr_accessor :headers
    attr_accessor :table

    def initialize(infilepath, opts={})
      @row_validator = opts[:row_validator] or nil
      @row_processor = opts[:row_processor] or nil
      @rows = CSV.read(infilepath)
      @headers = nil
    end

    def process
      $field_mapping = @field_mapping
      prepare_headers  # manipulates upper part of CSV to obtain a top row of headers ready for mapping
      trim_whitespace_from_headers
      map_headers_to_internal_names  # replaces headers with value from @field_mapping or nil if not present
      remove_unmapped_columns  # remove columns not present in @field_mapping
      convert_array_rows_to_hashes  # headers become the keys
      remove_badly_formed_rows if @row_validator  # all rows are accepted if no validator is provided
      subprocess_rows if @processor
      get_records
    end

    def prepare_headers
      @headers = @rows.shift
      @row_transform = 2  # +1 for counting from 0, +1 for header row
    end

    def trim_whitespace_from_headers
      @headers.map!{ |header| header ? header.strip : header }  # strip non-nil headers
    end

    def map_headers_to_internal_names
      @headers.map!{ |h| self.class.field_mapping[h] }
    end

    def remove_unmapped_columns
      num_cols = @rows.first.length
      col_indices = (0...num_cols).reject { |i| @headers[i].nil? }  # any columns under headers unmatched by field_mapping are rejected
      @rows = @rows.transpose.values_at(*col_indices).transpose
      @headers.compact! 
    end

    def convert_array_rows_to_hashes  # this allows us to map in the next step
      @rows = rows.map { |row| Hash[ @headers.zip(row) ] }
    end

    def remove_badly_formed_rows  # globals are set for the validator to log errors
      $file = @filename
      @rows = @rows.map.with_index do |row, i|
        $row = i + @row_transform
        @row_validator.new(row).validate
      end
      @rows.compact!  # remove nil values that replace invalid rows
    end

    def process_rows
      @rows = @rows.map_with_index do |row, i|
        $row = i + @row_transform
        @row_processor.new(row).process
      end
    end

    def table
      CSV::Table.new(@rows)
    end

    #def validate_row(row)
      #check_for_empty_row
      #empty_fields = self.class.required_fields.map { |f| row[f] ? nil : f }
      #empty_fields.compact!
      #$column = empty_fields
      ##binding.pry if row.has_key?(:authors)
      #raise HippoDataError.new(:incomplete_row) unless empty_fields.empty?
    #end

    def get_records
      table.map { |row| Record.new(row.to_hash) }
    end

    def file(infilepath)
      File.open(infilepath, 'w') { |file| file.write(@table.to_csv) }
    end

  end

end
