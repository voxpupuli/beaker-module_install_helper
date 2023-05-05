# frozen_string_literal: true

require 'spec_helper'

describe Beaker::ModuleInstallHelper do
  describe 'hosts_to_install_module_on' do
    context 'with a split master/agent setup' do
      let(:hosts) do
        [
          { 'roles' => %w[master database dashboard classifier] },
          { 'roles' => ['agent'] },
        ]
      end

      it 'returns a node with master role' do
        expect(hosts_to_install_module_on.first['roles']).to include 'master'
      end
    end

    context 'with a split agent only setup' do
      let(:hosts) { [{ 'roles' => ['agent'] }] }

      it 'returns a node with master role' do
        expect(hosts_to_install_module_on.first['roles']).to include 'agent'
      end
    end
  end

  describe 'module_name_from_metadata' do
    let(:module_metadata) { { 'name' => 'puppetlabs-vcsrepo' } }

    it 'Removes author from name' do
      res = module_name_from_metadata
      expect(res).to eq('vcsrepo')
    end
  end

  describe 'module_metadata' do
    before do
      $module_source_dir = '/a/b/c/d'
      allow(File).to receive(:exist?)
        .with('/a/b/c/d/metadata.json')
        .and_return(true)
      allow(File).to receive(:read)
        .with('/a/b/c/d/metadata.json')
        .and_return('{"name": "puppetlabs-vcsrepo"}')
    end

    it 'returns hash with correct data' do
      expect(module_metadata['name']).to eq('puppetlabs-vcsrepo')
    end
  end

  describe 'get_module_source_directory' do
    let(:call_stack) { ['/a/b/c/d/e/f/g/spec_helper_acceptance.rb'] }
    let(:call_stack_no_metadata) { ['/test/test/test/spec_helper_acceptance.rb'] }

    before do
      allow(File).to receive(:exist?).with(anything).and_return(false)
      allow(File).to receive(:exist?).with('/a/metadata.json').and_return(true)
    end

    it 'traverses file tree until it finds a folder containing metadata.json' do
      expect(get_module_source_directory(call_stack)).to eq('/a')
    end

    it 'traverses file tree without a metadata.json file' do
      expect(get_module_source_directory(call_stack_no_metadata)).to be_nil
    end
  end

  describe 'install_module_on' do
    let(:module_source_dir) { '/a/b/c/d' }
    let(:host) { { 'roles' => %w[master database dashboard classifier] } }

    context 'without options' do
      before do
        $module_source_dir = '/a/b/c/d'
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).and_return('{"name": "puppetlabs-vcsrepo"}')

        allow_any_instance_of(Beaker::DSL::InstallUtils::ModuleUtils)
          .to receive(:copy_module_to)
          .with(anything)
          .and_return(false)

        allow_any_instance_of(Beaker::DSL::InstallUtils::ModuleUtils)
          .to receive(:copy_module_to)
          .with(host, source: module_source_dir, module_name: 'vcsrepo')
          .and_return(true)
      end

      it 'copy module to given host' do
        expect(install_module_on(host)).to be true
      end
    end

    context 'with options' do
      before do
        $module_source_dir = '/a/b/c/d'
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).and_return('{"name": "puppetlabs-vcsrepo"}')

        allow_any_instance_of(Beaker::DSL::InstallUtils::ModuleUtils)
          .to receive(:copy_module_to)
          .with(anything)
          .and_return(false)

        allow_any_instance_of(Beaker::DSL::InstallUtils::ModuleUtils)
          .to receive(:copy_module_to)
          .with(host, source: module_source_dir, module_name: 'vcsrepo', protocol: 'rsync')
          .and_return(true)
      end

      it 'copy module to given host' do
        expect(install_module_on(host, protocol: 'rsync')).to be true
      end
    end
  end

  describe 'module_version_matching_requirement' do
    context 'with simple version requirement, no upper bound' do
      it 'return latest matching version' do
        res = module_version_from_requirement('puppetlabs-ntp', '= 6.0.0')
        expect(res).to eql('6.0.0')
      end
    end

    context 'with version range requirement with an upper bound' do
      it 'return latest matching version' do
        res = module_version_from_requirement('puppetlabs-ntp',
                                              '>= 4.0.0 < 6.0.0')
        expect(res).to eql('5.0.0')
      end
    end
  end

  describe 'module_dependencies_from_metadata' do
    before do
      allow_any_instance_of(described_class)
        .to receive(:module_metadata)
        .and_return(input_metadata)
    end

    context 'with multiple dependencies with versions' do
      let(:input_metadata) do
        {
          'name' => 'puppetlabs-vcsrepo',
          'dependencies' => [
            {
              'name' => 'puppetlabs/stdlib',
              'version_requirement' => '>= 4.13.1 <= 4.14.0',
            }, {
              'name' => 'puppetlabs/concat',
              'version_requirement' => '>= 2.0.0 <= 2.2.0',
            },
          ],
        }
      end

      let(:desired) do
        [
          { module_name: 'puppetlabs-stdlib', version: '4.14.0' },
          { module_name: 'puppetlabs-concat', version: '2.2.0' },
        ]
      end

      it 'returns dependencies array with 2 dependencies and their versions' do
        dependencies = module_dependencies_from_metadata
        expect(dependencies).to eq(desired)
      end
    end

    context 'with multiple dependencies without versions' do
      let(:input_metadata) do
        {
          'name' => 'puppetlabs-vcsrepo',
          'dependencies' => [
            { 'name' => 'puppetlabs/stdlib' },
            { 'name' => 'puppetlabs/concat' },
          ],
        }
      end

      let(:desired) do
        [
          { module_name: 'puppetlabs-stdlib' },
          { module_name: 'puppetlabs-concat' },
        ]
      end

      it 'returns dependencies array with 2 dependencies without version' do
        dependencies = module_dependencies_from_metadata
        expect(dependencies).to eq(desired)
      end
    end

    context 'with empty dependencies' do
      let(:input_metadata) do
        {
          'name' => 'puppetlabs-vcsrepo',
          'dependencies' => [],
        }
      end
      let(:desired) { [] }

      it 'returns empty dependencies array' do
        dependencies = module_dependencies_from_metadata
        expect(dependencies).to eq(desired)
      end
    end

    context 'with no dependencies' do
      let(:input_metadata) { { 'name' => 'puppetlabs-vcsrepo' } }
      let(:desired) { [] }

      it 'returns empty dependencies array' do
        dependencies = module_dependencies_from_metadata
        expect(dependencies).to eq(desired)
      end
    end
  end

  describe 'version_requirements_from_string' do
    context 'with simple version requirement containing lower bound' do
      let(:lower_bound) { '>= 2.0.0' }

      it 'return array with single gem version dependency objects' do
        res = version_requirements_from_string(lower_bound)
        expect(res).to eql([Gem::Dependency.new('', lower_bound)])
      end
    end

    context 'with complex version requirement containing upper bounds' do
      let(:lower_bound) { '>= 2.0.0' }
      let(:upper_bound) { '< 3.0.0' }

      it 'return array with 2 gem version dependency objects' do
        res = version_requirements_from_string("#{lower_bound} #{upper_bound}")
        expect(res).to eql([Gem::Dependency.new('', lower_bound),
                            Gem::Dependency.new('', upper_bound),])
      end
    end
  end

  describe 'forge_host' do
    context 'without env variables specified' do
      it 'returns production forge host' do
        allow(ENV).to receive(:[]).with('BEAKER_FORGE_HOST').and_return(nil)

        expect(forge_host).to eq('https://forge.puppet.com/')
      end
    end

    context 'with BEAKER_FORGE_HOST env variable specified' do
      it 'returns specified forge host' do
        allow(ENV).to receive(:[]).with('BEAKER_FORGE_HOST').and_return('http://anotherhost1.com')

        expect(forge_host).to eq('http://anotherhost1.com')
      end
    end
  end

  describe 'forge_api' do
    context 'without env variables specified' do
      it 'returns production forge api' do
        allow(ENV).to receive(:[]).with('BEAKER_FORGE_HOST').and_return(nil)
        allow(ENV).to receive(:[]).with('BEAKER_FORGE_API').and_return(nil)

        expect(forge_api).to eq('https://forgeapi.puppetlabs.com/')
      end
    end

    context 'with BEAKER_FORGE_HOST and BEAKER_FORGE_API env variables specified' do
      it 'returns specified forge api with trailing slash' do
        allow(ENV).to receive(:[]).with('BEAKER_FORGE_HOST').and_return('custom')
        allow(ENV).to receive(:[]).with('BEAKER_FORGE_API').and_return('an-api-url/')

        expect(forge_api).to eq('https://an-api-url/')
      end
    end
  end

  describe 'install_module_dependencies_on' do
    before do
      allow_any_instance_of(described_class)
        .to receive(:module_metadata)
        .and_return(input_metadata)
    end

    context 'with 1 dependencies with version' do
      let(:a_host) { { name: 'a_host' } }
      let(:dependency) do
        { module_name: 'puppetlabs-stdlib', version: '4.14.0' }
      end
      let(:input_metadata) do
        {
          'name' => 'puppetlabs-vcsrepo',
          'dependencies' => [
            {
              'name' => 'puppetlabs/stdlib',
              'version_requirement' => '>= 4.13.1 <= 4.14.0',
            },
          ],
        }
      end

      it 'installs the modules' do
        expect_any_instance_of(Beaker::DSL::InstallUtils::ModuleUtils)
          .to receive(:install_puppet_module_via_pmt_on)
          .with(a_host, dependency)
          .exactly(1)

        install_module_dependencies_on(a_host)
      end
    end

    context 'with 2 dependencies without version' do
      let(:input_metadata) do
        {
          'name' => 'puppetlabs-vcsrepo',
          'dependencies' => [
            { 'name' => 'puppetlabs/stdlib' },
            { 'name' => 'puppetlabs/concat' },
          ],
        }
      end
      let(:a_host) { { name: 'a_host' } }
      let(:dependency1) { { module_name: 'puppetlabs-concat' } }
      let(:dependency2) { { module_name: 'puppetlabs-stdlib' } }

      it 'installs both modules' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
        expect_any_instance_of(Beaker::DSL::InstallUtils::ModuleUtils)
          .to receive(:install_puppet_module_via_pmt_on)
          .with(a_host, dependency1)
          .exactly(1)

        expect_any_instance_of(Beaker::DSL::InstallUtils::ModuleUtils)
          .to receive(:install_puppet_module_via_pmt_on)
          .with(a_host, dependency2)
          .exactly(1)

        install_module_dependencies_on(a_host)
      end
    end
  end

  describe 'install_module_from_forge_on' do
    let(:a_host) { { name: 'a_host' } }
    let(:dependency) { { module_name: 'puppetlabs-stdlib', version: '4.14.0' } }
    let(:input_module_name) { 'puppetlabs/stdlib' }
    let(:input_module_version_requirement) { '>= 4.13.1 <= 4.14.0' }

    it 'installs the module' do
      expect_any_instance_of(Beaker::DSL::InstallUtils::ModuleUtils)
        .to receive(:install_puppet_module_via_pmt_on)
        .with(a_host, dependency)
        .exactly(1)

      install_module_from_forge_on(a_host, input_module_name, input_module_version_requirement)
    end
  end

  describe 'module_version_from_requirement' do
    context 'when looking up resolvable version contraints for a valid module' do
      it 'gets a response', live_fire: true do
        ver = module_version_from_requirement('puppetlabs-vcsrepo', '>= 1 < 2')
        expect(ver).to eq '1.5.0'
      end
    end

    context 'when looking up *unresolvable* version contraints for a valid module' do
      it 'gets a response', live_fire: true do
        expect do
          module_version_from_requirement('puppetlabs-vcsrepo', '> 1.4 < 1.5')
        end.to raise_error(/^No release version found matching 'puppetlabs-vcsrepo' '> 1.4 < 1.5'/)
      end
    end

    context 'when looking up metadata for a *invalid* module name' do
      it 'gets a response', live_fire: true do
        expect do
          module_version_from_requirement('puppet-does-not-exist', '>= 1 < 2')
        end.to raise_error(/^Puppetforge API error/)
      end
    end
  end
end
