FROM solr:8

ENV SOLR_PORT=8026

COPY --chown=solr:solr . /var/solr/data/biblio
COPY --chown=solr:solr ./examples /examples


RUN start-local-solr \
    && bash /examples/load_into_solr.sh \
    && stop-local-solr \
    && cp -r /var/solr/biblio /tmp

CMD cp -r /tmp/biblio /var/solr && solr-foreground
