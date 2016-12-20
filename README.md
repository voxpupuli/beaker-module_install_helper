## beaker-module\_install\_helper

This gem is simply an abstraction for the various functions that are performed within the `spec/spec_helper_acceptance.rb` files across the modules to standardise how these are implemented.

### Usage
The below example will install the module from source on the host with role 'master', if that doesn't exist, on all hosts with role 'agent'. Otherwise it will be installed on all hosts.
```ruby
require 'beaker/module_install_helper'
install_module
```

The below example will install the module from source on the specified host.
```ruby
require 'beaker/module_install_helper'
install_module_on(host)
```

This example will install git on 2 hosts. If osfamily fact equals 'RedHat' the package named git will be installed. Likewise for Debian, the git-core package will be installed.
```ruby
hosts = [a_debian_beaker_host, a_redhat_beaker_host]
dependencies =
    [{
         name:  'git',
         type:  :package,
         facts: [{ name: 'osfamily', operator: :equal, value: 'RedHat' }]
     }, {
        name:  'git-core',
        type:  :package,
        facts: [{ name: 'osfamily', operator: :equal, value: 'Debian' }]
    }]
    
    install_module_dependencies_on(hosts, dependencies)
```

### Assumptions
* Module under test has a valid metadata.json file at the root of the module directory.

### `install_module`
This will call `install_module_on` on the hosts with role 'master'. If there are none, the module will be install on all hosts with the role 'agent', again, if there are none, the module will be installed on all hosts.

### `install_module_on(host)`
This will install the module under test on the specified host using the local source. The module name will be derived from the name property of the module's metadata.json file, assuming it is in format author-modulename.

### `install_module_dependencies_on(hosts, dependencies)`
This will install a list of dependencies on the specified host either from forge or github, depending on the specified dependencies. See below [Dependency Format](####Dependency Format) section and [Fact Constrain Format](####Fact Constrain Format) section for details on how to format the given dependencies.
#### Dependency Format
Dependencies must be specified to `install_module_dependencies_on` as either a hash of a single dependency or an array of dependencies in a valid dependency format as defined below, here is an example:
```ruby
{ name: 'git', type: :package, facts: []}
```
#####Paramters
* name - Required. Name of the dependency
* type - Required. Currently only :package type supported. Uses beakers `install_package` method to perform package install using the dependencies name attribute
* facts - Optional. If specified, must be array of valid fact constraint hashes.

#### Fact Constrain Format
Below is an example of a fact constraint hash that can be specified as an array of hashes inside a dependency hash.
```ruby
{ name: 'osfamily', operator: :equal, value: 'RedHat' }
OR
{ name: 'osfamily', operator: :not_in, value: ['RedHat', 'Debian'] }
```
#####Parameters
* name - Required. Name of the fact as a string
* operator - Required. Must be on of 4 supported operators symbols:
  * :equal
  * :not_equal
  * :in
  * :not_in
* value - Required. Must be a string if the operator used is :equal or :not_equal. Must be an array if operator is :in or :not_in

### Support
No support is supplied or implied. Use at your own risk.

### TODO
 * Implement :module dependency type for the `install_module_dependencies_on` method to install a dependant module