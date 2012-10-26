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
      @collapser = (data[:collapser] ? eval(data[:collapser]) : nil)
      @validator = (data[:validator] ? eval(data[:validator]): RecordValidator)
      @row_transform = (data[:row_transform] or 2)
      @tests = data[:tests]
      @field_mapping = (data[:field_mapping] or nil)
      @required_fields = (data[:required_fields] or nil)
      @prepare_headers_proc = (data[:prepare_headers] or nil)
      @auxilary_data_path = (data[:auxilary_data_path] ? File.expand_path(data[:auxilary_data_path], directory) : nil)
      #data[:processors].unshift("CSVPort::RecordValidator") unless data[:processors].first.include?("Validator")  #default
      @processors = data[:processors].map do |processor|
        eval(processor)
      end
      @loader = @processors.pop
      @filepath = File.expand_path(filename, directory)
      @filetype = File.extname(filename).delete('.')
    end

    def load
      $file = @filename
      puts "---LOADING #{@filename}......................"
      data = @cleaner.new(@filepath, prepare_headers: @prepare_headers_proc, field_mapping: @field_mapping).process
      #binding.pry
      data = @collapser.new(data).process if @collapser
      data.compact!
      #binding.pry
      data = data.map.with_index { |record, i| $row = i + @row_transform; validate_record(record) }
      data.compact!
      #binding.pry
      data = data.map.with_index { |record, i| $row = i + @row_transform; process_record(record) }
      data.compact!
      #data.flatten!  # a single record may be expanded to multiple records during processing
      #binding.pry
      data.each_with_index { |record_set, i| $row = i + @row_transform; record_set.each { |record| load_record(record) }}
      #records.each_with_index do |record, i|
        #$record = i + cleaned_file.record_transform
        #record = @record_class.new(record)  # convert the hash to a Record
        #load_record(record)
      #end
      puts "----- #{@filename} LOADED......................"
    end

      def validate_record(record)
        @validator.new(record, tests: @tests, required_fields: @required_fields).process
      rescue InvalidRecordError => e
        #binding.pry
        e.log
        return nil
      end


    def process_record(start_record)
      records = [start_record]  # we use an array to allow for expansion of the record
      @processors.each do |processor|
        #records = records.map { |record| processor.new(record).process }
        records = records.map { |record| processor_step(processor, record) }
        records.flatten!
        records.compact!  # drop records that threw exceptions
      end
      #binding.pry
      return records
    end

    def processor_step(processor, record)
      #binding.pry
      processor.new(record).process
    rescue InvalidRecordError => e
      e.log
      return nil
    end

    def load_record(record)
      if @auxilary_data_path
        @loader.new(record, auxilary_data_path: @auxilary_data_path).load 
      else
        @loader.new(record).load
      end
    rescue InvalidRecordError => e
      e.log
      return nil
    end

    #def processor_step(processor, record)
      #input = get_processor_input(processor, record)
      #if processor.code.class == Proc
        #output = processor.code.call(*input)
      #else  # is a class
        #output = processor.code.new(*input).process
      #end
      #record = merge_processor_output(output, processor, record)
    #end

    #def get_processor_input(processor, record)
      #input = (processor.inputs == :all ? [record] : record.fields.values_at(processor.inputs))
    #end

    #def merge_processor_output(output, processor, record)
      #if processor.inputs == :all
        #record = output
      #else  # must be merged
        #processor.outputs.zip(output).each do |field, value|
          #record.field = value
        #end
      #end
      #return record
    #end

    #def load_record(record)
      #@record_loader.new(record).load
    #rescue LoadingError => e
      #e.log
    #end

    #def clean
      #@cleaner.new(@filepath, record_validator: @record_validator)
    #end

    #def process_cleaned_records
      #@records.each do |record|
        #@processors.each do |processor_data|
          #input_fields, processor, output_field = processor_data.values_at(:input_fields, :processor, :output_field)
          #input = (input_fields == :all ? record : record.values_at(input_fields))
          #record[output_field] = (processor.class == Proc ? processor.call(*input) : processor.new(*input).process)
        #end
      #end
    #end

  end

end
