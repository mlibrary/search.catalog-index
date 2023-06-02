FROM ruby:3.2 AS development

ARG UNAME=app
ARG UID=1000
ARG GID=1000

# Install Vim (optional)
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  vim-tiny

RUN gem install bundler

RUN groupadd -g ${GID} -o ${UNAME}
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME}
RUN mkdir -p /gems && chown ${UID}:${GID} /gems

USER $UNAME

ENV BUNDLE_PATH /gems

WORKDIR /app

CMD ["bundle", "exec", "sidekiq", "-q", "support", "-r", "./sidekiq.rb"]

FROM development AS production

COPY --chown=${UID}:${GID} . /app

RUN bundle install
