require 'csv_port/templates'

module CSVPort

  module Commands

    def self.newproject(root_path)
      @root_path = root_path
      @project_name = File.basename(root_path)
      Dir.mkdir(root_path) unless Dir.exists?(root_path)
      folders = ['data', 'db', 'bin', 'lib', "lib/#{project_name}"]
      folders.each do |folder|
        folderpath = File.expand_path(folder, root_path)
        Dir.mkdir(folderpath)
      end
      create_file('config.rb') { |str| str.gsub('!!NAME!!', project_name) }
      create_file('bin/build')
      create_file("lib/#{project_name}", :lib_base) do |str|
        camelcase_str = project_name.to_s.split('_').map{ |word| word[0].upcase + word[1..-1] }.join('')
        str.gsub('!!NAME!!', camelcase_str)
      end
      create_file('data/error_log.json')
      create_file('db/db_connection.rb')
      puts "New project created at #{root_path}"
    end

    def self.create_file(path, template_name=nil)
      template_name ||= File.basename(path, '.*')
      str = Templates.send(template_name)
      str = yield(str) if block_given?  # processing on the block
      filepath = File.expand_path(path, @root_path)
      File.write(filepath, str)
      FileUtils.chmod('+x', filepath) if File.extname(filepath).empty?
    end

  end

end

