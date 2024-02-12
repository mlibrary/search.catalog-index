FROM ruby:3.2

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  apt-transport-https


RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  vim-tiny

RUN gem install bundler

RUN mkdir -p /gems 


COPY Gemfile* /app/

ENV BUNDLE_PATH /gems


WORKDIR /app
RUN bundle install

COPY . /app


CMD ["bundle", "exec", "ruby", "mock-ht.rb", "-o", "0.0.0.0"]
