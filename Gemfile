# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :test do
  gem 'beaker'
  gem 'bundler', '>= 1.9', '< 3'
  gem 'rake', '~> 13.0'
  gem 'rspec', '~> 3.0'
end

group :development do
  gem 'pry'
  gem 'pry-byebug'
end

group :coverage, optional: ENV.fetch('COVERAGE', nil) != 'yes' do
  gem 'codecov', require: false
  gem 'simplecov-console', require: false
end

group :release do
  gem 'faraday-retry', require: false
  gem 'github_changelog_generator', require: false
end
