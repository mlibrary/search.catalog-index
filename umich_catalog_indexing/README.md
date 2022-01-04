# University of Michigan Solr Indexing for the catalog

## Most common usages for the scripts in /bin

```
# default SOLR_URL="http://localhost:8025/solr/biblio"
# default port is 8025
#
# If present, $SOLR_URL trumps everything else

bin/index_today <port> # logfile automatically created in logs/daily/
bin/index_date 20190901 <optional port>  <optional_logfile>
bin/catchup_since 20190901 <optional port> # run all the dailies including that date

bin/index_file /path/to/file.seq.gz <optional port> <optional_logfile>

bin/update_tmaps # re-derive HLB file and HT collection codes

```

### index_today <optional port> <optional logfile>

* Like everything else, presumes port 8025 unless a port number is passed
* Again like everything else, if $SOLR_URL is set that trumps all
* Automatically figures out the date
* Just runs `bin/index_date` on the right date
* Puts a logfile in logs/daily/daily/daily_yyyymmdd.txt by default


### catchup_since YYYYMMDD <optional port> <optional logfile>

* Figures out the start date and today's date
* ...and calls index_date repeatedly

### index_date YYYYMMDD <optional port> <optional logfile>

* Runs `bin/delete_ids`
  * Assumes there are no deletes if the file isn't found
* Runs `bin/index_file` for the marc file
  * ...but errors out if the marc file isn't found

### index_file /path/to/file.seq[.gz] <optional port> <optional logfile>

* Index that file, but doesn't do the deletes

## Where are all the important variables / locations / etc. set?

`bin/utils.sh`. This is called by just about everything else. It sets the default port, sets up bash logging,
figures out the solr url, etc.

## What other scripts are available?

* `update_tmaps` -- update HLB and  the translation maps.
* `commit <optional port>` -- just send a commit

The following are not yet functional in a useful way
* `delete_all`
* `test_marc_file_for_hlb`
* `fullindex`

These are low-level files called by the above
* `tindex`
* `utils.sh`

## Notes

Lots of dead code in here, vestiges of when the umich/ht indexing was unified

## Docker startup
* Need to get a copy of the HathiTrust overlap file (named `overlap_umich.tsv)` into `overlap/`

Then:
`docker-compose build`
`docker-compose run --rm web bundle exec fetch_new_hlb ./lib/translation_maps`
`docker-compose up`

