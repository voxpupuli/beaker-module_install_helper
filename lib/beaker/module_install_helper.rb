require 'beaker'

# Provides method for use in module test setup to install the module under
# test and it's dependencies on the specified hosts
module Beaker::ModuleInstallHelper
  include Beaker::DSL

  # This method calls the install_module_on method for each host which is a
  # master, or if no master is present, on all agent nodes.
  def install_module
    install_module_on hosts_to_install_module_on
  end

  # This method will install the module under test on the specified host(s) from
  # the source on the local machine
  def install_module_on(host)
    copy_module_to(host,
                   source:      @module_source_dir,
                   module_name: module_name_from_metadata)
  end

  # This method will install the module under tests dependencies on the
  # specified host
  def install_module_dependencies_on(_host, _dependencies)
    raise 'Not Implemented Yet'
  end

  # This method will return array of all masters. If no masters exist, it will
  # return all agent nodes. If no nodes tagged master or agent exist, all nodes
  # will be returned
  def hosts_to_install_module_on
    masters = hosts_with_role(hosts, :master)
    return masters unless masters.empty?

    agents = hosts_with_role(hosts, :agent)
    return agents unless agents.empty?

    hosts
  end

  # This method will read the 'name' attribute from metadata.json file and
  # remove the first segment. E.g. puppetlabs-vcsrepo -> vcsrepo
  def module_name_from_metadata
    res = get_module_name module_metadata['name']
    raise 'Error getting module name' unless res
    res[1]
  end

  # This method uses the module_source_directory path to read the metadata.json
  # file into a json array
  def module_metadata
    metadata_path = "#{@module_source_dir}/metadata.json"
    unless File.exist?(metadata_path)
      raise "Error loading metadata.json file from #{@module_source_dir}"
    end
    JSON.parse(File.read(metadata_path))
  end

  # Use this property to store the module_source_dir, so we don't traverse
  # the tree every time
  def get_module_source_directory(search_in)
    module_source_dir = nil
    # here we go up the file tree and search the directories for a
    # valid metadata.json
    while module_source_dir.nil? && search_in.length > 1
      # remove last segment (file or folder, doesn't matter)
      search_in = File.dirname(search_in)

      # Append metadata.json, check it exists in the directory we're searching
      metadata_path = File.join(search_in, 'metadata.json')
      module_source_dir = search_in if File.exist?(metadata_path)
    end
    module_source_dir
  end
end

include Beaker::ModuleInstallHelper
# Use the caller (requirer) of this file to begin search for module source dir
@module_source_dir = get_module_source_directory caller[0][/[^:]+/]
