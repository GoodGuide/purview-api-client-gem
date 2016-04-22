# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'purview_api/version'

Gem::Specification.new do |s|
  s.name = "purview-api"
  s.version = PurviewApi.VERSION
  s.authors = ["The wonderful people at UL/GoodGuide"]
  s.summary = "Purview API gem"
  s.description = "Gem to access the Purview API"
  s.homepage = "https://github.com/GoodGuide/purview-api"
  s.rubyforge_project = "goodguide"
  s.require_paths = ["lib"]
  s.files = Dir['Gemfile', 'purview-api.gemspec', 'lib/**/*.rb']
  s.test_files = Dir["spec/**/*_spec.rb"]

  s.add_dependency('activemodel')
  s.add_dependency('activesupport')
  s.add_dependency('faraday')
  s.add_dependency('faraday_middleware')
  s.add_dependency('faraday_middleware-multi_json')
  s.add_dependency('workqueue')
  s.add_dependency('hashie')
  s.add_dependency('json')

  # We duplicate Rails libraries here to specify version in development only
  # http://yehudakatz.com/2010/12/16/clarifying-the-roles-of-the-gemspec-and-gemfile/
  s.add_development_dependency('activemodel', '>= 5.0.0.beta3')
  s.add_development_dependency('activesupport', '>= 5.0.0.beta3')
  s.add_development_dependency('rspec')
  s.add_development_dependency('rr')
  s.add_development_dependency('rake')
  s.add_development_dependency('yajl-ruby')
  s.add_development_dependency('webmock')
  s.add_development_dependency('vcr')
  s.add_development_dependency('pry')
end
