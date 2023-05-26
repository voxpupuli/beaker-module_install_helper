## beaker-module\_install\_helper

[![License](https://img.shields.io/github/license/voxpupuli/beaker-module_install_helper.svg)](https://github.com/voxpupuli/beaker-module_install_helper/blob/master/LICENSE)
[![Test](https://github.com/voxpupuli/beaker-module_install_helper/actions/workflows/test.yml/badge.svg)](https://github.com/voxpupuli/beaker-module_install_helper/actions/workflows/test.yml)
[![Release](https://github.com/voxpupuli/beaker-module_install_helper/actions/workflows/release.yml/badge.svg)](https://github.com/voxpupuli/beaker-module_install_helper/actions/workflows/release.yml)
[![RubyGem Version](https://img.shields.io/gem/v/beaker-module_install_helper.svg)](https://rubygems.org/gems/beaker-module_install_helper)
[![RubyGem Downloads](https://img.shields.io/gem/dt/beaker-module_install_helper.svg)](https://rubygems.org/gems/beaker-module_install_helper)
[![Donated by Puppet Inc](https://img.shields.io/badge/donated%20by-Puppet%20Inc-fb7047.svg)](#transfer-notice)

**This gem is deprecated. Vox Pupuli now uses [beaker_puppet_helpers](https://github.com/voxpupuli/beaker_puppet_helpers)**

This gem is simply an abstraction for the various functions that are performed within the `spec/spec_helper_acceptance.rb` files across the modules to standardise how these are implemented.

### Usage
The below example will install the module from source on the host with role 'master', if that doesn't exist, on all hosts with role 'agent'. Otherwise it will be installed on all hosts.
```ruby
require 'beaker/module_install_helper'
install_module_dependencies
install_module

# Install a testing only dependency, not specified in metadata
install_module_from_forge('puppetlabs-inifile', '>= 1.0.0 <= 50.0.0')
```

The below example will install the module from source on the specified host and install module dependencies specified in metadata.json on the host
```ruby
require 'beaker/module_install_helper'
install_module_dependencies_on(host)
install_module_on(host)
```

### Assumptions
* Module under test has a valid metadata.json file at the root of the module directory.

### `install_module`
This will call `install_module_on` on the hosts with role 'master'. If there are none, the module will be install on all hosts with the role 'agent', again, if there are none, the module will be installed on all hosts.

### `install_module_on(host)`
This will install the module under test on the specified host using the local source. The module name will be derived from the name property of the module's metadata.json file, assuming it is in format author-modulename.

### `install_module_dependencies`
This will call `install_module_dependencies_on` on the hosts with role 'master'. If there are none, the module will be install on all hosts with the role 'agent', again, if there are none, the module dependencies will be installed on all hosts.

### `install_module_dependencies_on`
This will install a list of dependencies on the specified host from the forge, using the dependencies list specified in the metadata.json file, taking into consideration the version constraints if specified.

**See:** [Alternative Forge Instances](#alternative-forge-instances)

### `install_module_from_forge(module_name, version_requirement)`
This will call `install_module_from_forge_on` on the hosts with role 'master'. If there are none, the module will be installed on all hosts with the role 'agent', again, if there are none, the module will be installed on all hosts.

### `install_module_from_forge_on(hosts, module_name, version_requirement)`
This will install a module from the forge on the given host(s). Module name must be specified in the `{author}-{module_name}` or `{author}/{module_name}` format. Version requirement must be specified to meet [this](https://docs.puppet.com/puppet/latest/modules_metadata.html#version-specifiers) criteria.
 
**See:** [Alternative Forge Instances](#alternative-forge-instances)

### Alternative Forge Instances
It is possible to use alternative forge instances rather than the production forge instance to install module dependencies by specifiying 2 environment variables, `BEAKER_FORGE_HOST` and `BEAKER_FORGE_API`. Both of these are required as the forge API is used under the hood to resolve version requirement boundary strings.

**Example Using Staging Forge**
```
BEAKER_FORGE_HOST=https://module-staging.puppetlabs.com BEAKER_FORGE_API=https://api-module-staging.puppetlabs.com BEAKER_debug=true bundle exec rspec spec/acceptance
```

### Support
No support is supplied or implied. Use at your own risk.

## Transfer Notice

This plugin was originally authored by [Puppet Inc](http://puppet.com).
The maintainer preferred that [Vox Pupuli](https://voxpupuli.org) take ownership of the module for future improvement and maintenance.
Existing pull requests and issues were transferred over, please fork and continue to contribute here.

## License

This gem is licensed under the Apache-2 license.

## Release information

To make a new release, please do:
* update the version in the gemspec file
* Install gems with `bundle install --with release --path .vendor`
* generate the changelog with `bundle exec rake changelog`
* Check if the new version matches the closed issues/PRs in the changelog
* Create a PR with it
* After it got merged, push a tag. GitHub actions will do the actual release to rubygems and GitHub Packages
