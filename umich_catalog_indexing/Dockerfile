FROM jruby:9.2
ARG UNAME=app
ARG UID=1000
ARG GID=1000

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  build-essential\
  libffi-dev \
  git

RUN groupadd -g ${GID} -o ${UNAME}
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME}
RUN mkdir -p /gems && chown ${UID}:${GID} /gems

RUN gem install bundler:2.3
USER $UNAME

ENV BUNDLE_PATH /gems
RUN mkdir -p /gems 

COPY --chown=${UID}:${GID} Gemfile* /app/

WORKDIR /app

#jobs=1 set because ffi not installing properly for traject-marc4j_reader gem
RUN bundle install --jobs=1

COPY --chown=${UID}:${GID} . /app/

CMD ["bundle", "exec", "sidekiq", "-r", "./bin/jobs.rb"]
