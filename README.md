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

### Assumptions
* Module under test has a valid metadata.json file at the root of the module directory.

### `install_module`
This will call `install_module_on` on the hosts with role 'master'. If there are none, the module will be install on all hosts with the role 'agent', again, if there are none, the module will be installed on all hosts.

### `install_module_on(host)`
This will install the module under test on the specified host using the local source. The module name will be derived from the name property of the module's metadata.json file, assuming it is in format author-modulename.

### `install_module_dependencies_on`
This will install a list of dependencies on the specified host either from forge or github, depending on the specified dependencies

### Support
No support is supplied or implied. Use at your own risk.

### TODO
 - Implement `install_module_dependencies_on`