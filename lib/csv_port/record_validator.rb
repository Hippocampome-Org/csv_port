module CSVPort

  class RecordValidator

    # takes a hash and performs various checks on it via the validate method
    # the validate method should be implemented by the including class and should
    # - return the row if it is valid
    # - return nil if it is invalid
    # - should set a global variable $col with the name of the field being checked
    # - should catch and file exceptions thrown by the various checks

    @tests = [
      {
        name: "empty record",
        field: nil,
        test: lambda { not @record.values.any? },
        error_data: {
          type: :empty_row 
        }
      },
      {
        name: "required_fields",
        field: nil,
        test: lambda { @record.select {|field, value| value.nil?}.any? },
        error_data: {
          type: :missing_field,
          fields: @record.select{ |field, value| value.nil? }.keys
        }
      }
    ]

    attr_accessor :tests

    def initialize(record)
      @record = record
      if self.class == RecordValidator
        @tests = self.class.tests
      else
        @tests = self.class.superclass.tests.merge(self.class.tests)
      end
    end

    def validate
      @tests.each do |test|
        $field = test[:field]
        pass = test[:test].call
        if not pass
          raise InvalidRecordError.new(test[:error_data])
        end
      end
    end

  end

end
