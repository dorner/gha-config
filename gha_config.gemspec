# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gha_config/version'

Gem::Specification.new do |spec|
  spec.name          = 'gha_config'
  spec.version       = GhaConfig::VERSION
  spec.authors       = ['Daniel Orner']
  spec.email         = ['daniel.orner@flipp.com']
  spec.summary       = 'Process GitHub Action workflow files'
  spec.description   = 'Write a longer description. Optional.'
  spec.homepage      = ''
  spec.required_ruby_version = '>= 2.3'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency('rubocop')
end
