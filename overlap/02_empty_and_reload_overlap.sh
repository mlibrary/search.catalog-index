dbname=bibliosearch
overlap_file=overlap_umich.tsv
tablename=overlap
password=pass

#function usage() {
  #echo "Usage: $0 name_of_uncompressed_overlapfile.tsv"
  #echo "Will empty out, and load to, $dbname:$tablename"
  #echo "Takes about 5mn"
  #exit 1
#}
    
#[ -z $1 ] && usage


echo "delete from $tablename; LOAD DATA LOCAL INFILE '$overlap_file' INTO TABLE $tablename" | mysql -h localhost -uroot --local-infile=1 -p$password $dbname
