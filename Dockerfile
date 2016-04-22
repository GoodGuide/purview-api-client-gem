FROM ruby:2.3.0

WORKDIR /app

COPY ./lib/PurviewApi/version.rb \
      /app/lib/PurviewApi/version.rb

COPY ./Gemfile purview-api.gemspec /app/

RUN bundle install

COPY . /app/

ENTRYPOINT ["/app/docker/runtime/entrypoint"]
