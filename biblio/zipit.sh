user=solr
password=SolrRocks
host=http://localhost:8983
cd conf
rm ../biblio.zip
zip -r ../biblio.zip .
cd ..
curl -u $user:$password -X DELETE   "$host/api/cluster/configs/biblio"
curl -u $user:$password -X PUT   --header "Content-Type: application/octet-stream"   --data-binary @biblio.zip   "$host/api/cluster/configs/biblio"
curl -u $user:$password "$host/solr/admin/collections?action=DELETE&name=biblio"
curl -u $user:$password "$host/solr/admin/collections?action=CREATE&name=biblio&numShards=1&collection.configName=biblio"
