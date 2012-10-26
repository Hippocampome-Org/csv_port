module CSVPort

  PackagerData = Struct.new(:id, :processor, :input_ports)

  class PackagerBlockParser

    def initialize(block)
      @block = block
    end

    def parse
      remove_packager
      remove_whitespace
      extract_id
      extract_processor
      extract_input_ports
      export
    end

    def remove_packager
      @block.slice!(/^packager/)
    end

    def remove_whitespace
      @block.strip!
    end

    def extract_id
      @id = @block.slice!(/^\S+/).to_sym
    end

    def export
      PackagerData.new(@id, @processor, @input_ports)
    end

    def extract_processor
      processor_pattern = /([A-Z]\S+)\s*(\{.+?\})?/
      @block.scan(processor_pattern) do |match_data|
        proc_class, opts = match_data[0..1] if match_data
      end
      proc_class = "Packager" if not proc_class
      @processor = ProcessorData.new(proc_class, opts)
    end

    def extract_input_ports
      match_data = @block.match(/input_ports => (.+?)(output_ports|$)/)
      if match_data
        @input_ports = match_data[1].strip.split(/,? /).map { |port| port.to_sym }
      else
        @input_ports = nil
      end
    end

  end

end
