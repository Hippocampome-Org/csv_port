# -*- encoding: utf-8 -*-
require File.expand_path('../lib/csv_port/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Sean Mackesey"]
  gem.email         = ["s.mackesey@gmail.com"]
  gem.description   = %q{csvport}
  gem.summary       = %q{csvport}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  #gem.executables   = ['csv_port']
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "csv_port"
  gem.require_paths = ["lib"]
  gem.version       = CSVPort::VERSION

  gem.add_dependency 'rchardet19'

end
