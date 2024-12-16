FROM bitnami/java:21

ARG UNAME=app
ARG UID=1000
ARG GID=1000

LABEL maintainer="mrio@umich.edu"

RUN groupadd -g ${GID} -o ${UNAME}
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME}
RUN mkdir -p /jars && chown ${UID}:${GID} /jars

USER $UNAME

RUN wget -O /jars/alma.tar.gz-to-marcinjson.jar https://github.com/mlibrary/alma.tar.gz-to-marcinjson/releases/download/1.0/alma.tar.gz-to-marcinjson.jar

WORKDIR /app
