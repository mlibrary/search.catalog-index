FROM solr:8.11.2

ENV SOLR_AUTH_TYPE="basic"
ENV SOLR_AUTHENTICATION_OPTS="-Dbasicauth=solr:SolrRocks"
ENV SOLR_OPTS="-Denable.packages=true"

COPY --chown=solr:solr conf /biblio

#the one I can't get rid of.
COPY --chown=solr:solr lib/lucene-umich-solr-filters-2.1-solr-8.8.2.jar  /var/solr/lib/lucene-umich-solr-filters-2.1-solr-8.8.2.jar

COPY --chown=solr:solr dev_init/security.json /var/solr/data/security.json
COPY --chown=solr:solr dev_init/solr_init.sh /usr/bin/solr_init.sh
ENTRYPOINT ["/usr/bin/solr_init.sh"]
