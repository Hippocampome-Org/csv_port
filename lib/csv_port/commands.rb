require 'csv_port/templates'

module CSVPort

  module Commands

    def self.newproject(root_path, opts={})
      @root_path = root_path
      @project_name = File.basename(root_path)
      @config_filepath = opts[:config_filepath]
      binding.pry
      Dir.mkdir(root_path) unless Dir.exists?(root_path)
      folders = ['data', 'db', 'bin', 'lib', "lib/#{project_name}"]
      folders.each do |folder|
        folderpath = File.expand_path(folder, root_path)
        Dir.mkdir(folderpath)
      end
      create_file('config.rb', copy_file: @config_filepath) { |str| str.gsub('!!NAME!!', project_name) }
      create_file('bin/build')
      create_file("lib/#{project_name}", :lib_base) do |str|
        module_name = camelcase_str(project_name)
        str.gsub('!!NAME!!', module_name)
        require_string = build_require_string
        str.gsub('!!REQUIRE!!', require_string)
      end
      create_file('data/error_log.json')
      create_file('db/db_connection.rb')
      puts "New project created at #{root_path}"
    end

    def self.create_file(path, opts={})
      template_name = (opts[:template_name] or File.basename(path, '.*'))
      copy_file = opts[:copy_file]
      filepath = File.expand_path(path, @root_path)
      if copy_file
        FileUtils.cp(copy_file, filepath)
      else
        str = Templates.send(template_name)
        str = yield(str) if block_given?  # processing on the block
        File.write(filepath, str)
      end
      FileUtils.chmod('+x', filepath) if File.extname(filepath).empty?
    end

    def build_require_string
      if @config_filepath
        config_lines = File.readlines(@config_filepath)
        require_line_arrays = ['cleaner', 'record_validator', 'record_loader'].map do |field|
          lines = config_lines.select { |line| line.match(/^\s*#{field}/) }
          require_line_array =  lines.map do |line|
            klass_name = line.slice(/::(.*)$/, 1)
            require_name = underscore_str(klass_name)
            require_line = 'require ' + @project_name + '/' + require_name
          end
        end
        require_lines = require_line_arrays.flatten
        require_string = require_lines.sort.join("\n")
      else
        require_string = ""
      end
      return require_string
    end

    def camelcase_str(str)
      str.to_s.split('_').map{ |word| word[0].upcase + word[1..-1] }.join('')
    end

    def underscore_str(str)
      str.gsub(/([a-z1-9])([A-Z])/, "\\1_\\2").downcase
    end

  end

end
