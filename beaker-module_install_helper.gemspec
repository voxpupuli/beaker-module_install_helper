# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'beaker-module_install_helper'
  spec.version       = '0.1.4'
  spec.authors       = ['Puppet']
  spec.email         = ['wilson@puppet.com']

  spec.summary       = 'A helper gem for use in a Puppet Modules ' \
                       'spec_helper_acceptance.rb file'
  spec.description   = 'A helper gem for use in a Puppet Modules ' \
                       'spec_helper_acceptance.rb file to help install the ' \
                       'module under test and its dependencies on the system ' \
                       'under test'
  spec.homepage      = 'https://github.com/puppetlabs/beaker-module_install_helper'
  spec.license       = 'Apache-2'

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*` \
                       .split("\n") \
                       .map { |f| File.basename(f) }
  spec.require_paths = ['lib']

  ## Testing dependencies
  spec.add_development_dependency 'rspec'

  # Run time dependencies
  spec.add_runtime_dependency 'beaker', '>= 2.0'
end
