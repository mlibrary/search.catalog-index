cd conf
rm ../biblio.zip
zip -r ../biblio.zip .
cd ..
curl -u solr:SolrRocks -X DELETE   "http://localhost:8983/api/cluster/configs/biblio"
curl -u solr:SolrRocks -X PUT   --header "Content-Type: application/octet-stream"   --data-binary @biblio.zip   "http://localhost:8983/api/cluster/configs/biblio"
curl -u solr:SolrRocks 'http://localhost:8983/solr/admin/collections?action=DELETE&name=biblio'
curl -u solr:SolrRocks 'http://localhost:8983/solr/admin/collections?action=CREATE&name=biblio&numShards=1&collection.configName=biblio'
