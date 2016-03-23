FROM ruby:2.3.0

WORKDIR /app

COPY . /app/

RUN bundle install

RUN ln -fs /app/docker/runtime/pryrc ~/.pryrc \
 && ln -fs /app/docker/runtime/bashrc ~/.bashrc

ENTRYPOINT ["/app/docker/runtime/entrypoint"]
