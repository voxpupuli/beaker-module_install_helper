require 'spec_helper'

describe Beaker::ModuleInstallHelper do
  context 'hosts_to_install_module_on' do
    context 'on split master/agent setup' do
      let(:hosts) do
        [
          { 'roles' => %w(master database dashboard classifier) },
          { 'roles' => ['agent'] }
        ]
      end

      it 'returns a node with master role' do
        expect(hosts_to_install_module_on.first['roles']).to include 'master'
      end
    end

    context 'on split agent only setup' do
      let(:hosts) { [{ 'roles' => ['agent'] }] }

      it 'returns a node with master role' do
        expect(hosts_to_install_module_on.first['roles']).to include 'agent'
      end
    end
  end

  context 'module_name_from_metadata' do
    let(:module_metadata) { { 'name' => 'puppetlabs-vcsrepo' } }

    it 'Removes author from name' do
      res = module_name_from_metadata
      expect(res).to eq('vcsrepo')
    end
  end

  context 'module_metadata' do
    before do
      $module_source_dir = '/a/b/c/d'
      allow(File).to receive(:exist?)
        .with('/a/b/c/d/metadata.json')
        .and_return(true)
      allow(File).to receive(:read)
        .with('/a/b/c/d/metadata.json')
        .and_return('{"name": "puppetlabs-vcsrepo"}')
    end

    it 'Returns hash with correct data' do
      expect(module_metadata['name']).to eq('puppetlabs-vcsrepo')
    end
  end

  context 'get_module_source_directory' do
    let(:search_in) { '/a/b/c/d/e/f/g/h.rb' }
    let(:search_in_no_metadata) { '/test/test/test/blah.rb' }

    before do
      allow(File).to receive(:exist?).with(anything).and_return(false)
      allow(File).to receive(:exist?).with('/a/metadata.json').and_return(true)
    end

    it 'traverses file tree until it finds a folder containing metadata.json' do
      expect(get_module_source_directory(search_in)).to eq('/a')
    end

    it 'traverses file tree without a metadata.json file' do
      expect(get_module_source_directory(search_in_no_metadata)).to be_nil
    end
  end

  context 'install_module_on' do
    let(:module_source_dir) { '/a/b/c/d' }

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

    let(:host) { { 'roles' => %w(master database dashboard classifier) } }

    it 'copy module to given host' do
      expect(install_module_on(host)).to be true
    end
  end

  context 'module_version_matching_requirement' do
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

  context 'module_dependencies_from_metadata' do
    before do
      allow_any_instance_of(described_class)
        .to receive(:module_metadata)
        .and_return(input_metadata)
    end

    context 'multiple dependencies with versions' do
      let(:input_metadata) do
        {
          'name' => 'puppetlabs-vcsrepo',
          'dependencies' => [
            {
              'name' => 'puppetlabs/stdlib',
              'version_requirement' => '>= 4.13.1 <= 4.14.0'
            }, {
              'name' => 'puppetlabs/concat',
              'version_requirement' => '>= 2.0.0 <= 2.2.0'
            }
          ]
        }
      end

      let(:desired) do
        [
          { module_name: 'puppetlabs-stdlib', version: '4.14.0' },
          { module_name: 'puppetlabs-concat', version: '2.2.0' }
        ]
      end

      it 'returns dependencies array with 2 dependencies and their versions' do
        dependencies = module_dependencies_from_metadata
        expect(dependencies).to eq(desired)
      end
    end

    context 'multiple dependencies without versions' do
      let(:input_metadata) do
        {
          'name' => 'puppetlabs-vcsrepo',
          'dependencies' => [
            { 'name' => 'puppetlabs/stdlib' },
            { 'name' => 'puppetlabs/concat' }
          ]
        }
      end

      let(:desired) do
        [
          { module_name: 'puppetlabs-stdlib' },
          { module_name: 'puppetlabs-concat' }
        ]
      end

      it 'returns dependencies array with 2 dependencies without version' do
        dependencies = module_dependencies_from_metadata
        expect(dependencies).to eq(desired)
      end
    end

    context 'empty dependencies' do
      let(:input_metadata) do
        {
          'name' => 'puppetlabs-vcsrepo',
          'dependencies' => []
        }
      end
      let(:desired) { [] }

      it 'returns empty dependencies array' do
        dependencies = module_dependencies_from_metadata
        expect(dependencies).to eq(desired)
      end
    end

    context 'no dependencies' do
      let(:input_metadata) { { 'name' => 'puppetlabs-vcsrepo' } }
      let(:desired) { [] }

      it 'returns empty dependencies array' do
        dependencies = module_dependencies_from_metadata
        expect(dependencies).to eq(desired)
      end
    end
  end

  context 'version_requirements_from_string' do
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
                            Gem::Dependency.new('', upper_bound)])
      end
    end
  end

  context 'install_module_dependencies_on' do
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
              'version_requirement' => '>= 4.13.1 <= 4.14.0'
            }
          ]
        }
      end

      before do
        expect_any_instance_of(Beaker::DSL::InstallUtils::ModuleUtils)
          .to receive(:install_puppet_module_via_pmt_on)
          .with(a_host, dependency)
          .exactly(1)
      end

      it 'installs the modules' do
        install_module_dependencies_on(a_host)
      end
    end

    context 'with 2 dependencies without version' do
      let(:input_metadata) do
        {
          'name' => 'puppetlabs-vcsrepo',
          'dependencies' => [
            { 'name' => 'puppetlabs/stdlib' },
            { 'name' => 'puppetlabs/concat' }
          ]
        }
      end
      let(:a_host) { { name: 'a_host' } }
      let(:dependency1) { { module_name: 'puppetlabs-concat' } }
      let(:dependency2) { { module_name: 'puppetlabs-stdlib' } }

      before do
        expect_any_instance_of(Beaker::DSL::InstallUtils::ModuleUtils)
          .to receive(:install_puppet_module_via_pmt_on)
          .with(a_host, dependency1)
          .exactly(1)

        expect_any_instance_of(Beaker::DSL::InstallUtils::ModuleUtils)
          .to receive(:install_puppet_module_via_pmt_on)
          .with(a_host, dependency2)
          .exactly(1)
      end

      it 'installs both modules' do
        install_module_dependencies_on(a_host)
      end
    end
  end
end
