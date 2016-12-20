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

  context 'is_valid_dependency' do
    context 'with valid parameters' do
      context 'without facts specified' do
        let(:dependency) do
          {
            name:  'git',
            type:  :package
          }
        end

        it 'returns true' do
          expect(valid_dependency?(dependency)).to be true
        end
      end

      context 'with valid facts specified' do
        let(:dependency) do
          {
            name:  'git',
            type:  :package,
            facts: [{ name: 'osfamily', operator: :equal, value: 'RedHat' }]
          }
        end

        it 'returns true' do
          expect(valid_dependency?(dependency)).to be true
        end
      end
    end

    context 'without a name specified' do
      let(:dependency) do
        {
          type:  :package
        }
      end

      it 'returns false' do
        expect(valid_dependency?(dependency)).to be false
      end
    end
    context 'without a type specified' do
      let(:dependency) do
        {
          name:  'git'
        }
      end

      it 'returns false' do
        expect(valid_dependency?(dependency)).to be false
      end
    end
  end

  context 'is_valid_fact_constraint' do
    context 'with valid parameters' do
      let(:fact_constraint) do
        { name: 'osfamily',
          operator: :equal,
          value: 'RedHat' }
      end

      it 'returns true' do
        expect(valid_fact_constraint?(fact_constraint)).to be true
      end
    end

    context 'with missing parameter' do
      let(:fact_constraint) do
        { operator: :equal,
          value: 'RedHat' }
      end

      it 'returns false' do
        expect(valid_fact_constraint?(fact_constraint)).to be false
      end
    end

    context 'without invalid operator' do
      let(:fact_constraint) do
        { name: 'osfamily',
          operator: :equal_wrong,
          value: 'RedHat' }
      end

      it 'returns false' do
        expect(valid_fact_constraint?(fact_constraint)).to be false
      end
    end

    context 'without invalid value' do
      context 'using in operator' do
        let(:fact_constraint) do
          { name: 'osfamily',
            operator: :equal,
            value: ['Test'] }
        end

        it 'returns false' do
          expect(valid_fact_constraint?(fact_constraint)).to be false
        end
      end

      context 'using equal operator' do
        let(:fact_constraint) do
          { name: 'osfamily',
            operator: :in,
            value: 'RedHat' }
        end

        it 'returns false' do
          expect(valid_fact_constraint?(fact_constraint)).to be false
        end
      end
    end
  end

  context 'host_meets_fact_constraint' do
    context 'host meets fact constraint' do
      context 'using equal operator' do
        let(:fact_constraint) do
          { name: 'osfamily',
            operator: :equal,
            value: 'RedHat' }
        end

        it 'returns true' do
          allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
            .to receive(:fact_on)
            .with(nil, 'osfamily')
            .and_return('RedHat')

          expect(meets_fact_constraint?(nil, fact_constraint)).to be true
        end
      end

      context 'using not_equal operator' do
        let(:fact_constraint) do
          { name: 'osfamily',
            operator: :not_equal,
            value: 'Debian' }
        end

        it 'returns true' do
          allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
            .to receive(:fact_on)
            .with(nil, 'osfamily')
            .and_return('RedHat')

          expect(meets_fact_constraint?(nil, fact_constraint)).to be true
        end
      end

      context 'using in operator' do
        let(:fact_constraint) do
          { name: 'osfamily',
            operator: :in,
            value: %w(RedHat Debian) }
        end

        it 'returns true' do
          allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
            .to receive(:fact_on)
            .with(nil, 'osfamily')
            .and_return('RedHat')

          expect(meets_fact_constraint?(nil, fact_constraint)).to be true
        end
      end

      context 'using not_in operator' do
        let(:fact_constraint) do
          { name: 'osfamily',
            operator: :not_in,
            value: %w(SLES Debian) }
        end

        it 'returns true' do
          allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
            .to receive(:fact_on)
            .with(nil, 'osfamily')
            .and_return('RedHat')

          expect(meets_fact_constraint?(nil, fact_constraint)).to be true
        end
      end
    end

    context 'host does not meet fact constraint' do
      context 'using equal operator' do
        let(:fact_constraint) do
          { name: 'osfamily',
            operator: :equal,
            value: 'RedHat' }
        end

        it 'returns false' do
          allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
            .to receive(:fact_on)
            .with(nil, 'osfamily')
            .and_return('Debian')

          expect(meets_fact_constraint?(nil, fact_constraint)).to be false
        end
      end

      context 'using not_equal operator' do
        let(:fact_constraint) do
          { name: 'osfamily',
            operator: :not_equal,
            value: 'Debian' }
        end

        it 'returns false' do
          allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
            .to receive(:fact_on)
            .with(nil, 'osfamily')
            .and_return('Debian')

          expect(meets_fact_constraint?(nil, fact_constraint)).to be false
        end
      end

      context 'using in operator' do
        let(:fact_constraint) do
          { name: 'osfamily',
            operator: :in,
            value: %w(RedHat SLES) }
        end

        it 'returns false' do
          allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
            .to receive(:fact_on)
            .with(nil, 'osfamily')
            .and_return('Debian')

          expect(meets_fact_constraint?(nil, fact_constraint)).to be false
        end
      end

      context 'using not_in operator' do
        let(:fact_constraint) do
          { name: 'osfamily',
            operator: :not_in,
            value: %w(SLES Debian) }
        end

        it 'returns false' do
          allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
            .to receive(:fact_on)
            .with(nil, 'osfamily')
            .and_return('Debian')

          expect(meets_fact_constraint?(nil, fact_constraint)).to be false
        end
      end
    end
  end

  context 'host_meets_dependency' do
    context 'host meets dependency' do
      context 'no facts specified' do
        let(:dependency) { { name: 'git', type: :package } }

        it 'returns true' do
          expect(meets_dependency?(nil, dependency)).to be true
        end
      end

      context '2 valid facts specified' do
        let(:dependency) do
          { name: 'git', type: :package, facts: [
            { name: 'osfamily', operator: :equal, value: 'RedHat' },
            { name: 'some_fact', operator: :equal, value: 'SomeVal' }
          ] }
        end

        it 'returns true' do
          allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
            .to receive(:fact_on)
            .with(nil, 'osfamily')
            .and_return('RedHat')

          allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
            .to receive(:fact_on)
            .with(nil, 'some_fact')
            .and_return('SomeVal')

          expect(meets_dependency?(nil, dependency)).to be true
        end
      end

      context '1 valid fact and 1 invalid fact specified' do
        let(:dependency) do
          { name: 'git', type: :package, facts: [
            { name: 'osfamily', operator: :equal, value: 'RedHat' },
            { name: 'some_fact', operator: :equal, value: 'SomeWrongVal' }
          ] }
        end

        it 'returns true' do
          allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
            .to receive(:fact_on)
            .with(nil, 'osfamily')
            .and_return('RedHat')

          allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
            .to receive(:fact_on)
            .with(nil, 'some_fact')
            .and_return('SomeVal')

          expect(meets_dependency?(nil, dependency)).to be true
        end
      end
    end

    context 'host does not meet dependency with 2 invalid facts specified' do
      let(:dependency) do
        { name: 'git', type: :package, facts: [
          { name: 'osfamily', operator: :equal, value: 'Debian' },
          { name: 'some_fact', operator: :equal, value: 'SomeWrongVal' }
        ] }
      end

      it 'returns false' do
        allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
          .to receive(:fact_on)
          .with(nil, 'osfamily')
          .and_return('RedHat')

        allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
          .to receive(:fact_on)
          .with(nil, 'some_fact')
          .and_return('SomeVal')

        expect(meets_dependency?(nil, dependency)).to be false
      end
    end
  end

  context 'install_module_dependencies_on' do
    context 'single dependency single host' do
      context 'no fact constraints supplied' do
        let(:host) { { name: 'ahost' } }
        let(:dependency) { { name: 'git', type: :package } }

        it 'calls install_package with single host and single package' do
          expect_any_instance_of(Beaker::DSL::Helpers::HostHelpers)
            .to receive(:install_package)
            .with(host, dependency[:name])
            .exactly(1)

          install_module_dependencies_on(host, dependency)
        end
      end

      context 'with fact constraints supplied' do
        let(:host) { { name: 'ahost' } }
        let(:dependency) do
          {
            name: 'git',
            type: :package,
            facts: [{ name: 'osfamily', operator: :equal, value: 'RedHat' }]
          }
        end

        it 'calls install_package with single host and single package' do
          allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
            .to receive(:fact_on)
            .with(host, 'osfamily')
            .and_return('RedHat')

          expect_any_instance_of(Beaker::DSL::Helpers::HostHelpers)
            .to receive(:install_package)
            .with(host, dependency[:name])
            .exactly(1)

          install_module_dependencies_on(host, dependency)
        end
      end
    end

    context 'multiple dependencies and multiple hosts' do
      let(:redhat_host) { { name: 'redhat_host' } }
      let(:debian_host) { { name: 'debian_host' } }
      let(:git_dependency) do
        {
          name: 'git',
          type: :package,
          facts: [{ name: 'osfamily', operator: :equal, value: 'RedHat' }]
        }
      end
      let(:gitcore_dependency) do
        {
          name: 'git-core',
          type: :package,
          facts: [{ name: 'osfamily', operator: :equal, value: 'Debian' }]
        }
      end

      it 'calls install_package once for each host' do
        allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
          .to receive(:fact_on)
          .with(redhat_host, 'osfamily')
          .and_return('RedHat')

        allow_any_instance_of(Beaker::DSL::Helpers::FacterHelpers)
          .to receive(:fact_on)
          .with(debian_host, 'osfamily')
          .and_return('Debian')

        expect_any_instance_of(Beaker::DSL::Helpers::HostHelpers)
          .to receive(:install_package)
          .with(redhat_host, git_dependency[:name])
          .exactly(1)

        expect_any_instance_of(Beaker::DSL::Helpers::HostHelpers)
          .to receive(:install_package)
          .with(debian_host, gitcore_dependency[:name])
          .exactly(1)

        install_module_dependencies_on([redhat_host, debian_host],
                                       [git_dependency, gitcore_dependency])
      end
    end
  end
end
