module CSVPort

  module Commands

    def newproject(path)
      Dir.mkdir(path) unless Dir.exists?(path)
      folders = ['data', 'db', 'bin', 'lib']
      folders.each do |folder|
        folderpath = File.expand_path(folder, path)
        Dir.mkdir(folderpath)
      end
      project_name = File.basename(path)
      config_str = CSVPort.make_config_str(project_name)
      config_filepath = File.expand_path('config.rb', path)
      File.write(config_filepath, config_str)
      puts "New project created at #{path}"
    end

  end

end
