FROM solr:8

ENV SOLR_PORT=8026

COPY --chown=solr:solr . /var/solr/data/biblio
COPY --chown=solr:solr ./examples /examples
