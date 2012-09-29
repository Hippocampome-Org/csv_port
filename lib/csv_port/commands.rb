require 'csv_port/templates'

module CSVPort

  module Commands

    def self.newproject(path)
      Dir.mkdir(path) unless Dir.exists?(path)
      folders = ['data', 'db', 'bin', 'lib']
      folders.each do |folder|
        folderpath = File.expand_path(folder, path)
        Dir.mkdir(folderpath)
      end
      project_name = File.basename(path)
      config_str = Templates.config
      config_str.gsub!('!!NAME!!', project_name)
      config_filepath = File.expand_path('config.rb', path)
      File.write(config_filepath, config_str)
      error_log_str = Templates.error_log
      error_log_filepath = File.expand_path('data/error_log.json', path)
      File.write(error_log_filepath, error_log_str)
      build_script_str = Templates.build_script
      build_script_filepath = File.expand_path('bin/build', path)
      File.write(build_script_filepath, build_script_str)
      FileUtils.chmod('+x', build_script_filepath)
      puts "New project created at #{path}"
    end

  end

end
