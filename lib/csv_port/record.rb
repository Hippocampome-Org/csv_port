module CSVPort

  class Record

    # Basically a struct with the Enumerable advantages of a hash

    attr_accessor :fields
    #attr_accessor :row_num

    def initialize(hash, processors={})
      @fields = hash
      @fields.keys.each do |f|
        self.class.send(:define_method, f) { @fields[f] }
      end
    end

  end

end
