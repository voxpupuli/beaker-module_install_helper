require 'beaker'

# Provides method for use in module test setup to install the module under
# test and it's dependencies on the specified hosts
module Beaker::ModuleInstallHelper
  # This method will install the module under test on the specified host
  def install_module_on(_host)
    raise 'Not Implemented Yet'
  end

  # This method will install the module under tests dependencies on the
  # specified host
  def install_module_dependencies_on(_host, _dependencies)
    raise 'Not Implemented Yet'
  end
end

include Beaker::ModuleInstallHelper
