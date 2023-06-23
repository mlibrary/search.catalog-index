if [ $# = 1 ]
then
  name=$1
else
  echo "need a configset name"
  exit
fi
export $(grep -v '^#' .env | xargs -d '\n')
curl -u $user:$password "$host/solr/admin/configs?action=DELETE&name=$name&omitHeader=true"
