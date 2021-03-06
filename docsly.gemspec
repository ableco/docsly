# -*- encoding: utf-8 -*-
require File.expand_path('../lib/docsly/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mike Potter"]
  gem.email         = ["mike@disrupto.com"]
  gem.description   = 'A method of documenting APIs.'
  gem.summary       = 'A method of documenting APIs.'
  gem.homepage      = 'http://github.com/disrupto/docsly'

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "docsly"
  gem.require_paths = ["lib"]
  gem.version       = Docsly::VERSION
end
