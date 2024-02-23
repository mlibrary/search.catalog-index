FROM ruby:3.2 AS development

ARG UNAME=app
ARG UID=1000
ARG GID=1000

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  build-essential\
  git \
  vim-tiny \
  ssh

RUN groupadd -g ${GID} -o ${UNAME}
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME}
RUN mkdir -p /gems && chown ${UID}:${GID} /gems

RUN gem install bundler

USER $UNAME

ENV BUNDLE_PATH /gems

WORKDIR /app

CMD ["bundle", "exec", "sidekiq", "-r", "./lib/sidekiq_jobs.rb"]

FROM development AS production

COPY --chown=${UID}:${GID} . /app

RUN bundle install
