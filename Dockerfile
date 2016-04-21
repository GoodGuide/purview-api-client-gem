FROM ruby:2.3.0

WORKDIR /app

COPY ./lib/goodguide/entity_soup/version.rb \
      /app/lib/goodguide/entity_soup/version.rb

COPY ./Gemfile goodguide-entity_soup.gemspec /app/

RUN bundle install

COPY . /app/

ENTRYPOINT ["/app/docker/runtime/entrypoint"]
