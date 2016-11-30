## beaker-module\_install\_helper

This gem is simply an abstraction for the various functions that are performed within the `spec/spec_helper_acceptance.rb` files across the modules to standardise how these are implemented.

### `install_module_on`

This will install the module under test on the specified host using the local source

### `install_module_dependencies_on`

This will install a list of dependencies on the specified host either from forge or github, depending on the specified dependencies

### Support

No support is supplied or implied. Use at your own risk.

### TODO
 - Implement `install_module_on`
 - Implement `install_module_dependencies_on`