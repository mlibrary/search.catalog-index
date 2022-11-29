#!/bin/bash

# enables solr to start with basic auth turned on
solr zk cp /var/solr/data/security.json zk:security.json -z zoo:2181

# uploads the configuration in the biblio directory
solr zk upconfig -z  zoo:2181 -n biblio -d /biblio

# runs docker entry-point.sh and whatever is in command
exec /opt/docker-solr/scripts/docker-entrypoint.sh "$@"
