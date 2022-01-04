function jruby_bin_dir()  {
    HERE=`dirname $0`
    SCRIPTDIR=`realpath $HERE`
    #echo `realpath "${SCRIPTDIR}/../../jruby/bin"`
    echo `realpath "$HOME/apps/jruby/bin"`
}

function port() {
    if [[ -z $PORT ]]; then
	#echo 8025
	echo 8026
    else
	echo $PORT
    fi
}

function solr_url() {
    if [[ -z $SOLR_URL ]]; then
      port=$1
      [[ -z $port ]] && port=`port`
      echo "http://localhost:${port}/solr/biblio"
    else
      echo $SOLR_URL
    fi
}

function find_marc_file_for_date() {
    local datestr=$1
    local datadir=$2
    if [[ -z $MARCFILEBASE ]]; then
	MARCFILEBASE="vufind_upd"
    fi
    echo "${datadir}/${MARCFILEBASE}_${datestr}.seq"
}

function find_del_file_for_date() {
    local datestr=$1
    local datadir=$2
    # search_2021072511_15655281340006381_delete
    if [ ! -d "$datadir/$datestr" ]; then
      echo "no datadir $datadir/$datestr"
      return
    fi

    if [ -f $datadir/$datestr/search_${datestr}*_delete.log ]; then
      echo -e `ls ${datadir}/${datestr}/search_${datestr}*_delete.log`
    else 
      echo
    fi
}

function find_zephir_file_for_date() {
    local datestr=$1
    local datadir=$2
    # zephir update files have the previous days date in their filename
    zephir_date=`date --date="$datestr -1 day" +"%Y%m%d"`
    # zephir_upd_20210726.json.gz

    if [ -f $datadir/zephir_upd_${zephir_date}.json* ]; then
      echo -e `ls $datadir/zephir_upd_${zephir_date}.json*`
    else 
      echo
    fi
}

function data_dir() {
    if [[ -z $DDIR ]]; then
	DDIR="/l/solr-vufind/data"
    fi
    echo $DDIR
}

function log() {
    local msg=$1
    local file=$2

    if [ ! -z $file ] && [ ! -f $file ]; then
	touch $file
    fi

    if [ -z $file ] || [ ! -z $TERM ]; then
	echo -e $msg
    fi

    if [ ! -z $file ]; then
	
	echo -e $msg >> $file 2>&1
    fi
}

function commit() {
    SOLR_URL=`solr_url`
    log "Commiting to ${SOLR_URL}/update"
    curl --silent --show-error  -H "Content-Type: application/json" -X POST -d'{"commit": {}}' "${SOLR_URL}/update" > /dev/null
}

function empty_solr() {
    SOLR_URL=`solr_url`
    log "Emptying $SOLR_URL"
    curl --silent --show-error  -H "Content-Type: application/json" -X POST -d'{"delete": {"query": "*:*"}}' "$SOLR_URL/update" > /dev/null
}
