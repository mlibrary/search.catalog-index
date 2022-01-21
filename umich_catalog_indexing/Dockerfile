FROM jruby:9.2
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
RUN gem update --system 3.2.3
USER $UNAME

ENV BUNDLE_PATH /gems
RUN mkdir -p /gems 

COPY --chown=${UID}:${GID} Gemfile* /app/

WORKDIR /app

RUN bundle install

COPY --chown=${UID}:${GID} . /app/

CMD ["bundle", "exec", "sidekiq", "-r", "./bin/jobs.rb"]
