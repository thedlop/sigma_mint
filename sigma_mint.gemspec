Gem::Specification.new do |s|
  s.name        = 'sigma_mint'
  s.version     = '0.1.1'
  s.summary     = "Simple ERGO asset creaiton library"
  s.description = "Provides basic utilities for minting assets on the ERGO blockchain."
  s.authors     = ["Dark Lord of Programming"]
  s.email       = 'thedlop@sent.com'
  s.homepage    = 'https://github.com/thedlop/sigma_mint'
  s.license       = 'MIT'
  s.files = Dir.glob("{lib}/**/*")
  s.files += %w(sigma_mint.gemspec README.md LICENSE)
  s.add_dependency 'dotenv', '~> 2.7.6'
  s.add_dependency 'sigma_rb', '~> 0.2.0'
  s.add_dependency 'faraday', '~> 2.2.0'
  s.add_dependency 'faraday-multipart', '~> 1.0.3'
  s.add_development_dependency 'test-unit', '~> 3.5'
  s.add_development_dependency 'yard', '~> 0.9.20'
  s.test_files = Dir["tests/**/*.rb"]
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 3.0.1'
end
