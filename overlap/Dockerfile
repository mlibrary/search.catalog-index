FROM mariadb

ENV MARIADB_USER bibliosearch
ENV MARIADB_PASSWORD bibliosearch_password
ENV MARIADB_DATABASE bibliosearch
ENV MARIADB_ROOT_PASSWORD pass

COPY 01_overlap_defs.sql /docker-entrypoint-initdb.d/
COPY 02_empty_and_reload_overlap.sh /docker-entrypoint-initdb.d/
COPY overlap.tsv /
