# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'drac/version'

Gem::Specification.new do |spec|
  spec.name          = 'drac'
  spec.version       = Drac::VERSION
  spec.authors       = ['DaWanda GmbH', 'Razvan Popa', 'Tadas Sce']
  spec.email         = ['dev@dawanda.com', 'razvan@dawanda.com', 'tadas@dawanda.com']

  spec.summary       = %q{Data Retrieval Accelerator with Cassandra}
  spec.description   = %q{Data Retreival Accelerator - Cassandara based caching mechanism}
  spec.homepage      = 'https://github.com/dawanda/drac'

  unless spec.respond_to?(:metadata)
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'cassandra-driver', '~> 2.1'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rspec', '~> 3.3'
  spec.licenses    = ['MIT']
end
