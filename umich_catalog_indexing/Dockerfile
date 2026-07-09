FROM ruby:3.2 AS development

ARG UID=1000
ARG GID=1000

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  build-essential\
  git \
  vim-tiny \
  ssh

RUN groupadd -g ${GID} -o app
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash app
RUN mkdir -p /gems && chown ${UID}:${GID} /gems

RUN gem install bundler

USER app

ENV BUNDLE_PATH=/gems
ENV PATH="$PATH:/app/bin"

WORKDIR /app

CMD ["bundle", "exec", "sidekiq", "-r", "./lib/sidekiq_jobs.rb"]

FROM development AS production

COPY --chown=${UID}:${GID} . /app

RUN bundle install
