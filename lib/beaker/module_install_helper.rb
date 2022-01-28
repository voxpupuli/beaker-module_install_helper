require 'beaker'
require 'beaker-puppet'

# Provides method for use in module test setup to install the module under
# test and it's dependencies on the specified hosts
module Beaker::ModuleInstallHelper
  include Beaker::DSL

  # This method calls the install_module_on method for each host which is a
  # master, or if no master is present, on all agent nodes.
  def install_module(opts = {})
    install_module_on(hosts_to_install_module_on, opts)
  end

  # This method will install the module under test on the specified host(s) from
  # the source on the local machine
  def install_module_on(host, opts = {})
    opts = {
      source: $module_source_dir,
      module_name: module_name_from_metadata
    }.merge(opts)
    copy_module_to(host, opts)
  end

  # This method calls the install_module_dependencies_on method for each
  # host which is a master, or if no master is present, on all agent nodes.
  def install_module_dependencies(deps = nil)
    install_module_dependencies_on(hosts_to_install_module_on, deps)
  end

  # This method will install the module under tests module dependencies on the
  # specified host(s) from the dependencies list in metadata.json
  def install_module_dependencies_on(hsts, deps = nil)
    hsts = [hsts] if hsts.is_a?(Hash)
    hsts = [hsts] unless hsts.respond_to?(:each)
    deps = deps.nil? ? module_dependencies_from_metadata : deps

    fh = ENV['BEAKER_FORGE_HOST']

    hsts.each do |host|
      deps.each do |dep|
        if fh.nil?
          install_puppet_module_via_pmt_on(host, dep)
        else
          with_forge_stubbed_on(host) do
            install_puppet_module_via_pmt_on(host, dep)
          end
        end
      end
    end
  end

  def install_module_from_forge(mod_name, ver_req)
    install_module_from_forge_on(hosts_to_install_module_on, mod_name, ver_req)
  end

  def install_module_from_forge_on(hsts, mod_name, ver_req)
    sub_mod_name = mod_name.sub('/', '-')
    dependency = {
      module_name: sub_mod_name,
      version: module_version_from_requirement(sub_mod_name, ver_req)
    }

    install_module_dependencies_on(hsts, [dependency])
  end

  # This method returns an array of dependencies from the metadata.json file
  # in the format of an array of hashes, containing :module_name and optionally
  # :version elements. If no dependencies are specified, empty array is returned
  def module_dependencies_from_metadata
    metadata = module_metadata
    return [] unless metadata.key?('dependencies')

    dependencies = []
    metadata['dependencies'].each do |d|
      tmp = { module_name: d['name'].sub('/', '-') }

      if d.key?('version_requirement')
        tmp[:version] = module_version_from_requirement(tmp[:module_name],
                                                        d['version_requirement'])
      end
      dependencies.push(tmp)
    end

    dependencies
  end

  # This method takes a module name and the version requirement string from the
  # metadata.json file, containing either lower bounds of version or both lower
  # and upper bounds. The function then uses the forge rest endpoint to find
  # the most recent release of the given module matching the version requirement
  def module_version_from_requirement(mod_name, vr_str)
    require 'net/http'
    uri = URI("#{forge_api}v3/modules/#{mod_name}")
    response = Net::HTTP.get_response(uri)
    raise "Puppetforge API error '#{uri}': '#{response.body}'" if response.code.to_i >= 400

    forge_data = JSON.parse(response.body)

    vrs = version_requirements_from_string(vr_str)

    # Here we iterate the releases of the given module and pick the most recent
    # that matches to version requirement
    forge_data['releases'].each do |rel|
      return rel['version'] if vrs.all? { |vr| vr.match?('', rel['version']) }
    end

    raise "No release version found matching '#{mod_name}' '#{vr_str}'"
  end

  # This method takes a version requirement string as specified in the link
  # below, with either simply a lower bound, or both lower and upper bounds and
  # returns an array of Gem::Dependency objects
  # https://docs.puppet.com/puppet/latest/modules_metadata.html
  def version_requirements_from_string(vr_str)
    ops = vr_str.scan(/[(<|>|=)]{1,2}/i)
    vers = vr_str.scan(/[(0-9|\.)]+/i)

    raise 'Invalid version requirements' if ops.count != 0 &&
                                            ops.count != vers.count

    vrs = []
    ops.each_with_index do |op, index|
      vrs.push(Gem::Dependency.new('', "#{op} #{vers[index]}"))
    end

    vrs
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
    metadata_path = "#{$module_source_dir}/metadata.json"
    unless File.exist?(metadata_path)
      raise "Error loading metadata.json file from #{$module_source_dir}"
    end
    JSON.parse(File.read(metadata_path))
  end

  # Use this property to store the module_source_dir, so we don't traverse
  # the tree every time
  def get_module_source_directory(call_stack)
    matching_caller = call_stack.select { |i| i =~ /(spec_helper_acceptance|_spec)/i }

    raise 'Error finding module source directory' if matching_caller.empty?

    matching_caller = matching_caller[0] if matching_caller.is_a?(Array)
    search_in = matching_caller[/[^:]+/]

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

  def forge_host
    fh = ENV['BEAKER_FORGE_HOST']
    unless fh.nil?
      fh = 'https://' + fh if fh !~ /^(https:\/\/|http:\/\/)/i
      fh += '/' unless fh != /\/$/
      return fh
    end

    'https://forge.puppet.com/'
  end

  def forge_api
    fa = ENV['BEAKER_FORGE_API']
    unless fa.nil?
      fa = 'https://' + fa if fa !~ /^(https:\/\/|http:\/\/)/i
      fa += '/' unless fa != /\/$/
      return fa
    end

    'https://forgeapi.puppetlabs.com/'
  end
end

include Beaker::ModuleInstallHelper
# Use the caller (requirer) of this file to begin search for module source dir
$module_source_dir = get_module_source_directory caller
