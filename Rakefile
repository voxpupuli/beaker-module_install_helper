# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

require 'rspec/core/rake_task'
desc 'Run spec tests using rspec'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ['--color']
  t.pattern = 'spec'
end

begin
  require 'rubygems'
  require 'github_changelog_generator/task'
rescue LoadError
  # github_changelog_generator isn't available, so we won't define a rake task with it
else
  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.header = <<-HEADER
      # Changelog

      # All notable changes to this project will be documented in this file.
    HEADER
    config.exclude_labels = %w[duplicate question invalid wontfix wont-fix skip-changelog]
    config.user = 'voxpupuli'
    config.project = 'beaker-module_install_helper'
    config.future_release = Gem::Specification.load("#{config.project}.gemspec").version
  end
end

task default: %w[
  rubocop
  spec
]
