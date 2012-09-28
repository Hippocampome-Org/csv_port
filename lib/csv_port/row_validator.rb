module CSVPort

  module RowValidator

    # takes a hash and performs various checks on it via the validate method
    # the validate method should be implemented by the including class and should
    # - return the row if it is valid
    # - return nil if it is invalid
    # - should set a global variable $col with the name of the field being checked
    # - should catch and file exceptions thrown by the various checks

    def initialize(row)
      @row = row
    end

    def check_for_empty_row
      raise EmptyRowError.new if not @row.values.any?
    end

    def check_for_required_fields
      required_values = @row.values_at(@required_fields)
      raise IncompleteRowError if not required_values.all?
    end

  end

end
