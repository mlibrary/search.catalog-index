#!/bin/bash

# adds the plugin repo
docker-compose exec solr bin/solr package add-repo umich-solr-plugins https://raw.githubusercontent.com/mlibrary/umich-solr-plugins/main

# installs the packages
docker-compose exec solr bin/solr package install umich_library_identifier_solr_filters
docker-compose exec solr bin/solr package install umich_solr_analyzed_string
