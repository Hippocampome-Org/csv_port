module CSVPort

  class RecordValidator

    # takes a hash and performs various checks on it via the validate method
    # the validate method should be implemented by the including class and should
    # - return the row if it is valid
    # - return nil if it is invalid
    # - should set a global variable $col with the name of the field being checked
    # - should catch and file exceptions thrown by the various checks

    def initialize(record)
      @record = record
    end

    def check_for_empty_record
      raise InvalidRecordError.new(:type => :empty_record) if not @row.values.any?
    end

    def check_for_required_fields
      missing_fields = @record.select { |field, value| value.nil? }
      raise InvalidRecordError.new(:type => :incomplete_record, :empty_fields => missing_fields.keys) if missing_fields.any?
    end

  end

end
