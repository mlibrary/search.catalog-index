#!/bin/bash

if test $# -lt 2; then
    echo
    echo "Usage: swap_cores.sh core1 core2"
    echo "Solr root url derived from  \$SOLR_URL (default: localhost:8025/solr/biblio)"
    echo
    exit 1
fi


core1=$1
core2=$2

if [ -z $SOLR_ROOT ]; then
    if [ ! -z $SOLR_URL ]; then
		components=(${SOLR_URL//\// });

	SOLR_ROOT="${components[0]}/${components[1]}/${components[2]}"
    else
	defaultsolr=1
	SOLR_ROOT="http://localhost:8025/solr"
	SOLR_URL="${SOLR_ROOT}/$core"
    fi
fi

echo -e "\n**************************************************************"
echo -e "\n"
if [ ! -z ${defaultsolr+x} ] ; then
    echo -e "\$SOLR_URL not set. Can't derive solr root"
    echo -e "   '$SOLR_ROOT' taken from default."
else
    echo -e "   '$SOLR_URL' taken from \$SOLR_URL"
fi

echo -e "\nSwapping cores $core1 and $core2 after 5 seconds"

pause=5
sleep $pause

curl "${SOLR_ROOT}/admin/cores?action=SWAP&core=${core1}&other=${core2}&wt=json"

