module CSVPort

  class SourceFile

    attr_accessor :filename
    attr_accessor :cleaner
    attr_accessor :record_loader
    attr_accessor :record_validator
    attr_accessor :filepath
    attr_accessor :filetype

    Processor = Struct.new(:inputs, :code, :outputs, :options)

    def initialize(data, directory)
      @filename = data[:filename]
      @cleaner = (data[:cleaner]  ? eval(data[:cleaner]) : CSVCleaner)
      data[:processors] << "CSVPort::RecordValidator" unless data[:processors].first.include?("Validator")  #default
      @processors = data[:processors].map do |processor|
        eval(processor)
      end
      @filepath = File.expand_path(filename, directory)
      @filetype = File.extname(filename).delete('.')
    end

    def load
      $file = source_file.filename
      puts "---LOADING #{source_file.filename}......................"
      loader_klass, loader_opts = @processors.pop.values
      data = @cleaner.new(@filepath).process
      data.each { |record| process_record(record) }
      #records.each_with_index do |record, i|
        #$record = i + cleaned_file.record_transform
        #record = @record_class.new(record)  # convert the hash to a Record
        #load_record(record)
      #end
      puts "----- #{source_file.filename} LOADED......................"
    end

    def process_record(start_record)
      records = [start_record]  # we use an array to allow for expansion of the record
      processors.each do |processor|
        records = records.map { |record| processor_step(processor, record) }
        records.flatten!
      end
    end

    def processor_step(processor, record)
      input = get_processor_input(processor, record)
      if processor.code.class == Proc
        output = processor.code.call(*input)
      else  # is a class
        output = processor.code.new(*input).process
      end
      record = merge_processor_output(output, processor, record)
    end

    def get_processor_input(processor, record)
      input = (processor.inputs == :all ? [record] : record.fields.values_at(processor.inputs))
    end

    def merge_processor_output(output, processor, record)
      if processor.inputs == :all
        record = output
      else  # must be merged
        processor.outputs.zip(output).each do |field, value|
          record.field = value
        end
      end
      return record
    end

    def load_record(record)
      @record_loader.new(record).load
    rescue LoadingError => e
      e.log
    end

    def clean
      @cleaner.new(@filepath, record_validator: @record_validator)
    end

    def process_cleaned_records
      @records.each do |record|
        @processors.each do |processor_data|
          input_fields, processor, output_field = processor_data.values_at(:input_fields, :processor, :output_field)
          input = (input_fields == :all ? record : record.values_at(input_fields))
          record[output_field] = (processor.class == Proc ? processor.call(*input) : processor.new(*input).process)
        end
      end
    end

  end

end
