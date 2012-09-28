require 'rchardet19'

require 'csv_port/version'
require 'csv_port/csv_cleaner'
require 'csv_port/row_validator'
require 'csv_port/sequel_loader'

module CSVPort

  # copies a set of files from the indirpath to the outdirpath
  def self.build_directory(indirpath, outdirpath, target_filenames, opts={})
    encoding = opts[:encoding]
    indir, outdir = Dir.new(indirpath), Dir.new(outdirpath)
    filenames = indir.select { |filename| target_filenames.include?(filename) }
    filenames.each { |filename| convert_copy(filename, outdir, encoding) }
  end

  def self.convert_copy(file, outdir, target_encoding, opts={})
    verbose = (opts[:verbose] or true)
    outfilepath = File.absolute_path(file, outdir)
    puts "File: " + file.inspect if verbose
    content = File.read(file)
    encoding_data = CharDet.detect(content)
    puts "Encoding Data: " + encoding_data.to_s if verbose
    if encoding_data.encoding == target_encoding
      outcontent = content
      puts "Copying %s to %s without conversion..." % [file.inspect, outdir] if verbose
    else
      outcontent = content.encode(target_encoding, encoding_data.encoding)
      puts "Converting %s to %s and copying to %s" % [file.inspect, target_encoding, outdir] if verbose
    end
    puts if verbose
    File.write(outfilepath, outcontent)
  end

end
