module CSVPort

  class InvalidRecordError < StandardError

    attr_accessor :data
    attr_accessor :error_type

    def initialize(data={})
      @data = data
      original_column_name = $field_mapping.invert[$field]
      @data.update({row: $row, field: $field})
    end

    def log(additional_data={})
      $builder.error_data_hash[:error_log].data << @data.merge(additional_data)
    end


  end

end
