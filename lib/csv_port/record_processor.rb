module CSVPort

  module RecordProcessor

    def unpack_fields
      fields = (@record.class == Record ? @record.fields : @record)
      fields.each do |key, value|
        ivar_name = '@' + key.to_s
        ivar_value = value
        instance_variable_set(ivar_name, ivar_value)
      end
    end

    def export_record
      pairs = self.instance_variables.map do |ivar| 
        key = ivar.to_s.delete('@').to_sym
        value = eval(ivar.to_s)
        [key, value]
      end
      hash = Hash[pairs]
      Record.new(hash)
    end

  end
end
