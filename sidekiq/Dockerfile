FROM ruby:3.1
ARG UNAME=app
ARG UID=1000
ARG GID=1000

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  build-essential\
  git

RUN groupadd -g ${GID} -o ${UNAME}
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME}
RUN mkdir -p /gems && chown ${UID}:${GID} /gems

RUN gem install bundler:2.3.4
USER $UNAME

ENV BUNDLE_PATH /gems
COPY --chown=${UID}:${GID} Gemfile* /app/

RUN mkdir -p /gems 

WORKDIR /app
RUN bundle install
