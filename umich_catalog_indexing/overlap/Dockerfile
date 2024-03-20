FROM mariadb

COPY 01_overlap_defs.sql /docker-entrypoint-initdb.d/
COPY 02_empty_and_reload_overlap.sh /docker-entrypoint-initdb.d/
COPY overlap.tsv /
