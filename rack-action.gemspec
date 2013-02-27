# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Paul Barry"]
  gem.email         = ["mail@paulbarry.com"]
  gem.description   = %q{a small, simple framework for generating Rack responses}
  gem.summary       = %q{a small, simple framework for generating Rack responses}
  gem.homepage      = "http://github.com/pjb3/rack-action"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rack-action"
  gem.require_paths = ["lib"]
  gem.version       = "0.2.0"

  gem.add_runtime_dependency "rack"
end
