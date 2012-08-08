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

  # s.add_dependency('faraday', '~> 0.7')
  # s.add_dependency('faraday_middleware')
  # s.add_dependency('hashie')
end
