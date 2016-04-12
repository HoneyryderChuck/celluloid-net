require File.expand_path('../lib/celluloid/net/version',__FILE__)

Gem::Specification.new do |spec|
  spec.name          = "celluloid-net"
  spec.version       = Celluloid::Net::VERSION
  spec.authors       = ["Tiago Cardoso"]
  spec.email         = ["cardoso_tiago@hotmail.com"]
  spec.summary       = "Celluloid IO-compatible Ruby Net clients"
  spec.description   = "Wrappers to the ruby standard network clients for many protocols"
  spec.homepage      = "https://github.com/TiagoCardoso1983/celluloid-net"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "celluloid-io"
  spec.add_development_dependency "timeout-extensions"
  
  spec.add_development_dependency "rake", 		"~> 10.0"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency "rspec"
end
