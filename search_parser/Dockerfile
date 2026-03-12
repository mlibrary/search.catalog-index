################################################################################
# BASE
################################################################################
FROM ruby:4.0-slim AS base

ARG UID=1000
ARG GID=1000
ARG NODE_MAJOR=20


RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  build-essential \
  libyaml-dev \
  curl \
  vim\
  git


RUN groupadd -g ${GID} -o app
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash app

ENV GEM_HOME=/gems
ENV PATH="$PATH:/gems/bin"
RUN mkdir -p /gems && chown ${UID}:${GID} /gems


ENV BUNDLE_PATH /app/vendor/bundle

# Change to app and back so that bundler created files in /gems are owned by the
# app user
USER app
RUN gem install bundler
USER root

WORKDIR /app

CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:4567"]

################################################################################
# DEVELOPMENT                                           								       # 
################################################################################
FROM base AS development

#RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
#git


USER app

################################################################################
# PRODUCTION                                                                   #
################################################################################
FROM base AS production


ENV BUNDLE_WITHOUT=development:test

COPY --chown=${UID}:${GID} . /app

USER app

RUN bundle install

