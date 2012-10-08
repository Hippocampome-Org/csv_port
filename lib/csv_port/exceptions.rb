module CSVPort

  class InvalidRecordError < StandardError

    attr_accessor :data
    attr_accessor :error_type

    def initialize(data={})
      @data = data
      original_column_name = $field_mapping.invert[$col]
      @data.update({row: $row, column: original_column_name})
    end

    def log(additional_data={})
      ERROR_DATA_HASH[:error_log] << @data.merge(additional_data)
    end


  end

  class EmptyFieldError < StandardError
  end

  class EmptyRowError < StandardError
  end

end
