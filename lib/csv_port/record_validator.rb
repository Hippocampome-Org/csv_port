module CSVPort

  class RecordValidator

    # takes a hash and performs various checks on it via the validate method
    # the validate method should be implemented by the including class and should
    # - return the row if it is valid
    # - return nil if it is invalid
    # - should set a global variable $col with the name of the field being checked
    # - should catch and file exceptions thrown by the various checks

    class << self
      attr_accessor :tests
      attr_accessor :required_fields  # no value for the base class
    end

    @tests = [
      {
        name: "not empty record",
        field: nil,
        test: lambda { @record.fields.values.any? },
        error_data: {
          type: :empty_row 
        }
      },
      {
        name: "required_fields",
        field: nil,
        test: lambda { @required_fields.map {|field| @record.fields[field]}.all? },
        error_data: lambda {
          {
            type: :missing_field,
            fields: @required_fields.select{ |field| @record.fields[field].nil? }
          }
        }
      }
    ]

    attr_accessor :tests

    def initialize(record, opts={})
      #binding.pry
      @record = record
      @required_fields = (self.class.required_fields or opts[:required_fields] or [])
      @tests = self.class.tests
      @tests += opts[:tests] if opts[:tests]
      #if self.class == RecordValidator
        #@tests = self.class.tests
      #else
        #@tests = self.class.superclass.tests.merge(self.class.tests)
      #end
    end

    def process
      @tests.each do |test|
        $field = test[:field]
        pass = instance_exec &test[:test]
        if not pass
          raise_exception(test)
        end
      end
      return @record
    end

    def raise_exception(test)
      if test[:error_data].class == Proc
        error_data = instance_exec &test[:error_data]
      else
        error_data = test[:error_data]
      end
      raise InvalidRecordError.new(error_data)
    end

  end

end
