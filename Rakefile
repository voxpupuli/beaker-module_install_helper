require 'bundler/gem_tasks'
require 'fileutils'
require 'rototiller'
require 'rubocop/rake_task'

task default: [:lint, :spec]

desc 'Run rubocop'
RuboCop::RakeTask.new(:lint) do |t|
  t.requires << 'rubocop-rspec'
end

require 'rspec/core/rake_task'
desc 'Run spec tests using rspec'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ['--color']
  t.pattern = 'spec'
end

desc 'Run acceptance tests of a puppet module'
rototiller_task :acceptance do |t|
  t.add_env(name: 'ACCEPTANCE_CMD',
            message: 'Command to use to run the acceptance tests of the module',
            default: 'bundle exec rspec spec/acceptance')

  t.add_env(name: 'ACCEPTANCE_GIT_REPO',
            message: 'Git repo of the module to test',
            default: 'https://github.com/puppetlabs/puppetlabs-ntp.git')

  t.add_env(name: 'ACCEPTANCE_GIT_REPO_FOLDER',
            message: 'Root folder within which to clone the module.',
            default: 'ntp')

  t.add_env(name: 'ACCEPTANCE_GIT_REF',
            message: 'Git repo reference of the module to test. Can be branch, commit sha or tag.',
            default: 'master')

  t.add_command do |c|
    # Create repo root folder
    c.name = <<-SCRIPT
mkdir -p spec/acceptance/.tmp &&
rm -rf spec/acceptance/.tmp/${ACCEPTANCE_GIT_REPO_FOLDER} &&
git clone ${ACCEPTANCE_GIT_REPO} spec/acceptance/.tmp/${ACCEPTANCE_GIT_REPO_FOLDER} &&
cd spec/acceptance/.tmp/${ACCEPTANCE_GIT_REPO_FOLDER} &&
git checkout ${ACCEPTANCE_GIT_REF} &&
cat Gemfile | sed -e "s/gem \'beaker-module_install_helper\', /gem \'beaker-module_install_helper\', :path => \'#{Shellwords.escape(File.dirname(__FILE__)).gsub('/', '\/')}\', /" > GemfileModified &&
echo 'Edited Gemfile: ' && cat GemfileModified &&
bundle install --gemfile=./GemfileModified --path=./.bundle/gems &&
${ACCEPTANCE_CMD}
    SCRIPT
  end
end
