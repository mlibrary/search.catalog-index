FROM ruby:3.1

LABEL maintainer="mrio@umich.edu"

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  apt-transport-https

RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  nodejs \
  vim

RUN gem install bundler:2.3


RUN mkdir -p /gems 


COPY Gemfile* /app/

ENV BUNDLE_PATH /gems


WORKDIR /app
RUN bundle install

COPY . /app


CMD ["bundle", "exec", "ruby", "mock-ht.rb", "-o", "0.0.0.0"]
