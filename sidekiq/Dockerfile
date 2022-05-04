ARG RUBY_VERSION=3.1
FROM ruby:${RUBY_VERSION}

ARG BUNDLER_VERSION=2.3.13
ARG UNAME=app
ARG UID=1000
ARG GID=1000

LABEL maintainer="mrio@umich.edu"

RUN gem install bundler:${BUNDLER_VERSION}
RUN bundle -v

RUN groupadd -g ${GID} -o ${UNAME}
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME}
RUN mkdir -p /gems && chown ${UID}:${GID} /gems

USER $UNAME

ENV BUNDLE_PATH /gems

WORKDIR /app

COPY --chown=${UID}:${GID} . /app
RUN bundle _${BUNDLER_VERSION}_ install

CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0"]
