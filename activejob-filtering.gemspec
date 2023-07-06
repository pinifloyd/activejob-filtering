# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/activejob/filtering/version'

Gem::Specification.new do |spec|
  spec.name          = 'activejob-filtering'
  spec.version       = ActiveJob::Filtering::VERSION
  spec.authors       = ['Hanchar Sergey']
  spec.email         = ['hanchar.sergey@gmail.com']

  spec.summary       = %q{Mask arguments from ActiveJob.}
  spec.description   = %q{This is ActiveJob's extension for arguments masking.}
  spec.homepage      = 'https://github.com/pinifloyd/activejob-filtering'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activejob'
  spec.add_runtime_dependency 'activesupport'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
