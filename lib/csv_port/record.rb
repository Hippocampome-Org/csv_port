module CSVPort

  class Record

    include Enumerable

    # Basically a struct with the Enumerable advantages of a hash

    attr_accessor :fields
    #attr_accessor :row_num

    def initialize(hash, processors={})
      @fields = hash
      @fields.keys.each do |f|
        self.class.send(:define_method, f) { @fields[f] }
      end
    end

    def [](field)
      @fields[field]
    end

    def each
      @fields.each { |key, value| yield(key, value) }
    end

  end

end
