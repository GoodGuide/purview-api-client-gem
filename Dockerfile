FROM ruby:2.3.0

WORKDIR /app

COPY . /app/

RUN bundle install

ENTRYPOINT ["/app/docker/runtime/entrypoint"]
