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

  # This method will install the module under test on the
  # specified host(s) from the source on the local machine
  def install_module_on(host)
    copy_module_to(host,
                   source:      @module_source_dir,
                   module_name: module_name_from_metadata)
  end

  # This method will install the module under tests dependencies on the
  # specified host(s)
  def install_module_dependencies_on(hosts, dependencies)
    dependencies = [dependencies] if dependencies.is_a?(Hash)

    if !dependencies.is_a?(Array) ||
       dependencies.any? { |dependency| !valid_dependency?(dependency) }
      raise 'Invalid dependencies supplied'
    end

    hosts = [hosts] unless hosts.is_a?(Array)
    hosts.each do |host|
      dependencies.each do |dependency|
        if meets_dependency?(host, dependency)
          install_dependency_on(host, dependency)
        end
      end
    end
  end

  # Validates the given dependency is valid and the returns true/false depending
  # on whether or not the given beaker host meets the given dependency fact
  # requirements. If no facts, always returns true.
  def meets_dependency?(host, dep)
    raise 'Invalid dependency' unless valid_dependency?(dep)

    # If no facts or any facts are valid, return true. Otherwise, return false
    return true unless dep.key?(:facts)
    return true if dep[:facts].any? { |fc| meets_fact_constraint?(host, fc) }
    false
  end

  # Validates the given fact constraint is valid and returns true/false
  # depending on whether or not the given beaker host meets the given
  # fact constraint
  def meets_fact_constraint?(host, fc)
    raise 'Invalid fact constraint' unless valid_fact_constraint?(fc)
    fact_value = fact_on(host, fc[:name])
    case fc[:operator]
    when :equal
      return fact_value == fc[:value]
    when :not_equal
      return fact_value != fc[:value]
    when :in
      return fc[:value].include?(fact_value)
    when :not_in
      return !fc[:value].include?(fact_value)
    else
      return false
    end
  end

  # This method performs the install of a dependency on the given beaker host.
  # Assumes the dependency given is valid and dependency type is :package, as
  # this is the only supported package type.
  def install_dependency_on(host, dependency)
    case dependency[:type]
    when :package
      install_package(host, dependency[:name])
    else
      raise "#{dependency[:type]} not yet supported"
    end
  end

  # Will return true/false depending on whether the given dependency is valid.
  # Dependency must be a hash in format { name: '', type: :package }. The
  # dependency may optionally contain an array of facts with the key, :facts
  def valid_dependency?(dependency)
    # Ensure its a hash and necessary keys exist in the hash
    return false unless dependency.is_a?(Hash)
    return false unless dependency.key?(:name) && dependency.key?(:type)

    # Ensure the type is in the specified list of dependency types supported
    return false unless [:package].include?(dependency[:type])

    # If fact constraints are specified for the dependency, ensure they're valid
    if dependency.key?(:facts)
      return false unless dependency[:facts].is_a?(Array)
      dependency[:facts].each do |fact_constraint|
        return false unless valid_fact_constraint?(fact_constraint)
      end
    end
    true
  end

  # Will return true/false depending on whether the given fact_constraint is a
  # hash in format { name: '', operator: :equal, value: 'val' OR ['val','val'] }
  def valid_fact_constraint?(fact_constraint)
    # Ensure its a hash and necessary keys exist in the hash
    return false unless fact_constraint.is_a?(Hash) &&
                        fact_constraint.key?(:name) &&
                        fact_constraint.key?(:operator) &&
                        fact_constraint.key?(:value)

    # Ensure parameter types are correct, name is a string, operator in
    # specified list and value correct type depending on operator
    return false unless fact_constraint[:name].is_a?(String) &&
                        [:equal,
                         :not_equal,
                         :in,
                         :not_in].include?(fact_constraint[:operator])

    return false if [:in, :not_in].include?(fact_constraint[:operator]) &&
                    !fact_constraint[:value].is_a?(Array)

    return false if [:equal, :not_equal].include?(fact_constraint[:operator]) &&
                    !fact_constraint[:value].is_a?(String)

    true
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
    while module_source_dir.nil? && search_in != File.dirname(search_in)
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
