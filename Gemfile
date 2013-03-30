source 'http://rubygems.org/'
gemspec

if ENV['RAILS_VERSION'].to_i == 2
  gem 'activesupport', '2.3.17'
  gem 'activerecord', '2.3.17'
else
  gem 'activesupport', '>=3'
  gem 'activerecord', '>=3'
end

gem 'json'

group :test, :development do
  gem 'rspec'
  gem 'rr'
  gem 'rake'
  gem 'yajl-ruby'
  gem 'webmock'
  gem 'vcr'
end
