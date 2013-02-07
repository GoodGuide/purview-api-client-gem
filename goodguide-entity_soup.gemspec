require './lib/goodguide/entity_soup/version'

Gem::Specification.new do |s|
  s.name = "goodguide-entity_soup"
  s.version = GoodGuide::EntitySoup.version
  s.authors = ["Simon Waddington"]
  s.email = ["simon@goodguide.com"]
  s.summary = "GoodGuide Entity Soup API gem"
  s.description = "Gem to access the GoodGuide Entity Soup API"
  s.homepage = "http://www.goodguide.com"
  s.rubyforge_project = "goodguide"
  s.files = Dir['Gemfile', 'goodguide-entity_soup.gemspec', 'lib/**/*.rb']

  s.add_dependency('faraday')
  s.add_dependency('workqueue')
  s.add_dependency('hashie')
  s.add_dependency('activemodel')
  s.add_dependency('activesupport')
end
