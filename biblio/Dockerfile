FROM solr:8 AS indexer

ENV SOLR_PORT=8026

COPY --chown=solr:solr . /var/solr/data/biblio
COPY --chown=solr:solr ./examples /examples

# The solr:8 Dockerfile includes
#
# VOLUME /var/solr 
# https://github.com/docker-solr/docker-solr/blob/master/8.11/Dockerfile#L118
# 
#
# Among other things, this means that anything we write to /var/solr/data
# during a RUN command will be lost:
# https://docs.docker.com/engine/reference/builder/#volume
# (Things copied with COPY do appear to persist.)
#
# Using multi-stage builds allows us to build the data, storing it in
# /tmp/biblio, and then copying from that temporary image into our final output
# image.

RUN mkdir /tmp/biblio && \
    ln -s /tmp/biblio /var/solr/biblio && \
    start-local-solr && \
    bash /examples/load_into_solr.sh && \
    stop-local-solr

FROM solr:8

ENV SOLR_PORT=8026

COPY --chown=solr:solr . /var/solr/data/biblio
COPY --from=indexer /tmp/biblio /var/solr/biblio
