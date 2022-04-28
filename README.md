# Catalog Solr Index
This is code for indexing MARC data published from Alma and HathiTrust into the Catalog Solr Index

## Prerequisits
`ssh-keygen` (Check `which ssh-keygen`. If you don't get anything install the `ssh` package.) 

## Set up Development environment

Clone and cd into the repo

Run the script to initialize ssh keys for the sftp server and umich_catalog_indexing
```
$ ./set_up_development_ssh_keys.sh
```

Copy the `umich_catalog_indexing/.env-example` to `umich_catalog_indexing/.env`
```
$ cp umich_catalog_indexing/.env-example to umich_catalog_indexing/.env
```

Get the actual Alma API key from a developer.

Get the `overlap_umich.tsv` file from a developer. Put it in the `overlap` folder.

Replace values in `umich_catalog_index/.env` with real keys. Ask a developer for the appropriate value

Build it
```
$ docker-compose build
```

Build the gems for the web service (the one that has traject)
```
$ docker-compose run --rm web bundle install
```

Turn it on in detached mode
```
$ docker-compose up -d
```

In a browser you can look at
http://localhost:8026 for the solr admin panel
http://localhost:9292/ for the sidekiq admin panel

To index an example record:
```
$ docker-compose run --rm web bundle exec irb -r ./lib/sidekiq_jobs.rb
irb(main):001:0> IndexIt.perform_async("search_daily_bibs/birds_2022021017_21131448650006381_new.tar.gz", "http://solr:8026/solr/biblio")
```
