module CSVPort

  class CSVCleaner

    class << self
      attr_accessor :field_mapping
      attr_accessor :filename
      attr_accessor :required_fields
    end

    attr_accessor :rows
    attr_accessor :headers
    attr_accessor :row_transform 
    attr_accessor :row_class

    def initialize(infilepath, opts={})
      @row_validator_class = opts[:row_validator_class] or nil
      @raw_rows = CSV.read(infilepath)
      @headers, @rows = nil, nil
      @table = clean
    end

    def clean
      prepare_headers  # manipulates upper part of CSV to obtain a top row of headers ready for mapping
      trim_whitespace_from_headers
      map_headers_to_internal_names  # replaces headers with value from @field_mapping or nil if not present
      remove_unmapped_columns  # remove columns not present in @field_mapping
      convert_array_rows_to_hashes  # headers become the keys
      remove_badly_formed_rows if @row_validator_class  # all rows are accepted if no validator is provided
      table = make_csv_table  # CSV::Table class
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

    def remove_unmapped_colmuns
      num_cols = @rows.first.length
      col_indices = (0...num_cols).reject { |i| @headers[i].nil? }  # any columns under headers unmatched by field_mapping are rejected
      @rows = @rows.transpose.values_at(*col_indices).transpose
      @headers.compact! 
    end

    def convert_array_rows_to_hashes
      @rows = rows.map { |row| Hash[ @headers.zip(row) ] }
    end

    def remove_badly_formed_rows  # globals are set for the validator to log errors
      $file = @filename
      @rows = @rows.map.with_index do |row, i|
        $row = i + @row_transform
        @row_validator_class.new(row).validate
      end
      @rows.compact!  # remove nil values that replace invalid rows
    end

    def validate_row(row)
      check_for_empty_row
      empty_fields = self.class.required_fields.map { |f| row[f] ? nil : f }
      empty_fields.compact!
      $column = empty_fields
      #binding.pry if row.has_key?(:authors)
      raise HippoDataError.new(:incomplete_row) unless empty_fields.empty?
    end

    def table
      @table
    end

    def hash_rows
      @table.map { |row| row.to_hash }
    end

    def file(infilepath)
      File.open(infilepath, 'w') { |file| file.write(@table.to_csv) }
    end

  end

end
