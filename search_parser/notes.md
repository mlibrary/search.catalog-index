# Query parser service notes

## Need to figure out

* what a query looks like for a title or author search (it comes in the query string)
* what the filter for dates looks like; for the basic we don't need to worry aobut it. We do this in advanced search. The logic for this should live in catalog api.

Input:
what kind of search? assuming that's one string.
query string
fq
rows
start
sort

All of these values mean something in solr (exept perhaps the kind of search. That's specific to this setup.)

The catalog api will know how fields/facets/filters in search map to solr terms.

the search parser will know what facets should be included in the response. That includes what fields and facets to return.

## Steps to accomplish this

1. DONE answer the "need to figure out"
2. set up search parser service to do query string, rows, start
3. get the service set up in k8s
4. get the catalog api to talk to the search parser service (at this point there will be real results)
5. get query parser api to handle the appropriate inputs. Do TDD at this point.
6. figure out what parameters the catalog api should be able to take in.
7. clean up output for availability
8. set up sort
9. set up fq for the libraries
10. set up ht search only logic
11. set up advanced search date handling

Then specialists.
