# coding: utf-8

Gem::Specification.new do |spec|
  spec.name = "watir_model"
  spec.version       = "0.5.8"
  spec.authors       = ["Titus Fortner"]
  spec.email         = ["titusfortner@gmail.com"]

  spec.summary = %q{This is a simple class for modelling test data.}
  spec.description = %q{This is a simple class for modelling test data. It is based on our experience with Watirmark::Model::Factory.}
  spec.homepage = "https://github.com/titusfortner/watir_model"
  spec.license = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'faker', "~> 1.5"
  spec.add_runtime_dependency 'yml_reader', '>= 0.6'

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"
end
