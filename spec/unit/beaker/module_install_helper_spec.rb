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
      @module_source_dir = '/a/b/c/d'
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

    before do
      allow(File).to receive(:exist?).with(anything).and_return(false)
      allow(File).to receive(:exist?).with('/a/metadata.json').and_return(true)
    end

    it 'traverses file tree until it finds a folder containing metadata.json' do
      expect(get_module_source_directory(search_in)).to eq('/a')
    end
  end

  context 'install_module_on' do
    let(:module_source_dir) { '/a/b/c/d' }

    before do
      @module_source_dir = '/a/b/c/d'
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

  context 'install_module_dependencies_on' do
    it 'raises not implemented error' do
      expect { install_module_dependencies_on(nil, nil) }
        .to raise_error /Not Implemented Yet/
    end
  end
end
