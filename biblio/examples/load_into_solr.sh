input="/examples/sample1.json"
while IFS= read -r line
do
cat << EOT | curl -X POST -H 'Content-Type:application/json'  --data-binary @- http://localhost:8026/solr/biblio/update/json?commit=true
[$line]
EOT
done < "$input"
