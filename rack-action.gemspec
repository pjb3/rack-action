Gem::Specification.new do |gem|
  gem.authors       = ["Paul Barry"]
  gem.email         = ["pauljbarry3@gmail.com"]
  gem.description   = "a small, simple framework for generating Rack responses"
  gem.summary       = "a small, simple framework for generating Rack responses"
  gem.homepage      = "http://github.com/pjb3/rack-action"

  gem.files         = `git ls-files`.split($ORS)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rack-action"
  gem.require_paths = ["lib"]
  gem.version       = "0.7.0"

  gem.add_runtime_dependency "rack"
end
