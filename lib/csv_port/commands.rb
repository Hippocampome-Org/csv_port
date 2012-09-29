require 'csv_port/templates'

module CSVPort

  module Commands

    def self.newproject(root_path)
      @root_path = root_path
      Dir.mkdir(path) unless Dir.exists?(path)
      folders = ['data', 'db', 'bin', 'lib']
      folders.each do |folder|
        folderpath = File.expand_path(folder, path)
        Dir.mkdir(folderpath)
      end
      project_name = File.basename(path)
      create_file('config.rb') { |str| str.gsub('!!NAME!!', project_name) }
      create_file('bin/build')
      create_file('data/error_log.json')
      create_file('db/db_connection.rb')
      puts "New project created at #{path}"
    end

    def self.create_file(path)
      filename = File.basename(path, '.*')
      str = Templates.send(filename)
      str = yield(str) if block_given?  # processing on the block
      filepath = File.expand_path('path', @root_path)
      File.write(filepath, str)
      FileUtils.chmod('+x', filepath) if File.extname(filepath).empty?
    end

  end

end

