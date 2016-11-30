source 'https://rubygems.org'

gemspec

group :test do
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
  gem 'bundler', '~> 1.9'
  gem 'rake', '~> 10.0'
  gem 'rspec', '~> 3'
  gem 'beaker', '2.52.0' if RUBY_VERSION <= '2.1.6'
  gem 'beaker' if RUBY_VERSION > '2.1.6'
end

group :development do
  gem 'pry'
  gem 'pry-byebug'
end
