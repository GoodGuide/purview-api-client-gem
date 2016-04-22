FROM ruby:2.3.0

WORKDIR /app

COPY ./lib/purview_api/version.rb \
      /app/lib/purview_api/version.rb

COPY ./Gemfile purview_api.gemspec /app/

RUN bundle install

COPY . /app/

ENTRYPOINT ["/app/docker/runtime/entrypoint"]
