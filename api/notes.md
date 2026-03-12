# Notes for Search Results

## Example solr results query

```
Below is close to what current search is asking for. Facet count is just limited to 50 instead of 500
http://bulleit-1.umdl.umich.edu:8026/solr/biblio/select?f.authorStr.facet.mincount=1&df=allfields&f.authorStr.facet.sort=count&f.hlb3Str.facet.offset=0&f.publishDateRange.facet.limit=50&qq1=%22jazz+singer+book%22&tie=0.1&f.institution.facet.sort=count&f.building.facet.mincount=1&f.hlb3Str.facet.sort=count&f.topicStr.facet.sort=count&f.authorStr.facet.limit=50&f.language.facet.sort=count&f.format.facet.limit=50&f.topicStr.facet.limit=50&f.building.facet.sort=count&qq=%22_query_\:\{\!edismax+mm%3D$default_mm+mm.autoRelax%3D$mm.autoRelax+tie%3D$tie+qf%3D$all_fields_qf+pf%3D$all_fields_pf+pf2%3D$all_fields_pf2+ps2%3D$all_fields_ps2+boost%3D$all_fields_boost+v%3D$q1\}%22&per_page=10&f.search_only.facet.offset=0&f.search_only.facet.mincount=1&qt=standard&f.building.facet.limit=50&f.institution.facet.limit=50&sort=score+desc&f.availability.facet.limit=50&f.search_only.facet.sort=count&default_mm=2%3C-1+5%3C67%25&f.geographicStr.facet.limit=50&mm.autoRelax=true&f.institution.facet.offset=0&f.hlb3Str.facet.mincount=1&f.geographicStr.facet.mincount=1&f.format.facet.offset=0&f.place_of_publication.facet.offset=0&f.topicStr.facet.mincount=1&page=1&t1=%22jazz+singer%22+book&f.place_of_publication.facet.mincount=1&f.language.facet.mincount=1&f.availability.facet.mincount=1&f.language.facet.offset=0&all_fields_pf2=title_author^500+title_equiv^80+title_l^50&fl=*,score&f.location.facet.mincount=1&f.publishDateRange.facet.offset=0&f.language.facet.limit=50&fq=institution:(UM\+Ann\+Arbor\+Libraries)&fq=%2B(new_availability:physical+OR+new_availability:hathi_trust_full_text_or_electronic_holding)&f.location.facet.sort=count&f.publishDateRange.facet.sort=count&all_fields_pf=title_equiv^40+title_top^20+title_rest^10+author^80+author_top^30+author_rest^20&f.format.facet.mincount=1&f.hlb3Str.facet.limit=50&f.geographicStr.facet.sort=count&f.institution.facet.mincount=1&facet.threads=10&clean_string=(%22jazz+singer%22+book)&wt=json&f.search_only.facet.limit=50&f.topicStr.facet.offset=0&f.location.facet.offset=0&q1=(%22jazz+singer%22+book)&facet.field=search_only&facet.field=availability&facet.field=format&facet.field=topicStr&facet.field=publishDateRange&facet.field=language&facet.field=location&facet.field=hlb3Str&facet.field=authorStr&facet.field=place_of_publication&facet.field=geographicStr&facet.field=institution&facet.field=building&f.place_of_publication.facet.sort=count&f.geographicStr.facet.offset=0&start=0&rows=10&all_fields_boost=product(+if(termfreq(%27format%27,+%27Journal%27),+1.4,+1),+max(+map(+query({!field+f%3Dtitle_common_exact+v%3D$q1},+1),+0,+1,+1,+180+),+map(+query({!field+f%3Dtitle_equiv_exact+v%3D$q1},+1),+0,+1,+1,+50+),+map(+query({!field+f%3Dtitle_a_exact+v%3D$q1},+1),+0,+1,+1,+10+)),+map(+query({!dismax+f%3Dtitle_author+v%3D$q1+mm%3D%22100%25%22},+1),+0,+1,+1,+50+),+)&f.availability.facet.sort=count&q=_query_:{!edismax+mm%3D$default_mm+mm.autoRelax%3D$mm.autoRelax+tie%3D$tie+qf%3D$all_fields_qf+pf%3D$all_fields_pf+pf2%3D$all_fields_pf2+ps2%3D$all_fields_ps2+boost%3D$all_fields_boost+v%3D$q1}&f.location.facet.limit=50&f.place_of_publication.facet.limit=50&f.authorStr.facet.offset=0&f.building.facet.offset=0&all_fields_ps2=2&all_fields_qf=allfieldsProper^2+allfields^1+title_common^50+title_equiv^10+mainauthor^80+author^50+isbn+issn+oclc+lccn+barcode+htid+callnosearch+bookplate&f.format.facet.sort=count&f.publishDateRange.facet.mincount=1&facet=true&f.availability.facet.offset=0


This is what we want. location is changed to collection. Facet count is 50
http://bulleit-1.umdl.umich.edu:8026/solr/biblio/select?f.authorStr.facet.mincount=1&df=allfields&f.authorStr.facet.sort=count&f.hlb3Str.facet.offset=0&f.publishDateRange.facet.limit=50&qq1=%22jazz+singer+book%22&tie=0.1&f.institution.facet.sort=count&f.building.facet.mincount=1&f.hlb3Str.facet.sort=count&f.topicStr.facet.sort=count&f.authorStr.facet.limit=50&f.language.facet.sort=count&f.format.facet.limit=50&f.topicStr.facet.limit=50&f.building.facet.sort=count&qq=%22_query_\:\{\!edismax+mm%3D$default_mm+mm.autoRelax%3D$mm.autoRelax+tie%3D$tie+qf%3D$all_fields_qf+pf%3D$all_fields_pf+pf2%3D$all_fields_pf2+ps2%3D$all_fields_ps2+boost%3D$all_fields_boost+v%3D$q1\}%22&per_page=10&f.search_only.facet.offset=0&f.search_only.facet.mincount=1&qt=standard&f.building.facet.limit=50&f.institution.facet.limit=50&sort=score+desc&f.availability.facet.limit=50&f.search_only.facet.sort=count&default_mm=2%3C-1+5%3C67%25&f.geographicStr.facet.limit=50&mm.autoRelax=true&f.institution.facet.offset=0&f.hlb3Str.facet.mincount=1&f.geographicStr.facet.mincount=1&f.format.facet.offset=0&f.place_of_publication.facet.offset=0&f.topicStr.facet.mincount=1&page=1&t1=%22jazz+singer%22+book&f.place_of_publication.facet.mincount=1&f.language.facet.mincount=1&f.availability.facet.mincount=1&f.language.facet.offset=0&all_fields_pf2=title_author^500+title_equiv^80+title_l^50&fl=*,score&f.collection.facet.mincount=1&f.publishDateRange.facet.offset=0&f.language.facet.limit=50&fq=institution:(UM\+Ann\+Arbor\+Libraries)&fq=%2B(new_availability:physical+OR+new_availability:hathi_trust_full_text_or_electronic_holding)&f.collection.facet.sort=count&f.publishDateRange.facet.sort=count&all_fields_pf=title_equiv^40+title_top^20+title_rest^10+author^80+author_top^30+author_rest^20&f.format.facet.mincount=1&f.hlb3Str.facet.limit=50&f.geographicStr.facet.sort=count&f.institution.facet.mincount=1&facet.threads=10&clean_string=(%22jazz+singer%22+book)&wt=json&f.search_only.facet.limit=50&f.topicStr.facet.offset=0&f.collection.facet.offset=0&q1=(%22jazz+singer%22+book)&facet.field=search_only&facet.field=availability&facet.field=format&facet.field=topicStr&facet.field=publishDateRange&facet.field=language&facet.field=collection&facet.field=hlb3Str&facet.field=authorStr&facet.field=place_of_publication&facet.field=geographicStr&facet.field=institution&facet.field=building&f.place_of_publication.facet.sort=count&f.geographicStr.facet.offset=0&start=0&rows=10&all_fields_boost=product(+if(termfreq(%27format%27,+%27Journal%27),+1.4,+1),+max(+map(+query({!field+f%3Dtitle_common_exact+v%3D$q1},+1),+0,+1,+1,+180+),+map(+query({!field+f%3Dtitle_equiv_exact+v%3D$q1},+1),+0,+1,+1,+50+),+map(+query({!field+f%3Dtitle_a_exact+v%3D$q1},+1),+0,+1,+1,+10+)),+map(+query({!dismax+f%3Dtitle_author+v%3D$q1+mm%3D%22100%25%22},+1),+0,+1,+1,+50+),+)&f.availability.facet.sort=count&q=_query_:{!edismax+mm%3D$default_mm+mm.autoRelax%3D$mm.autoRelax+tie%3D$tie+qf%3D$all_fields_qf+pf%3D$all_fields_pf+pf2%3D$all_fields_pf2+ps2%3D$all_fields_ps2+boost%3D$all_fields_boost+v%3D$q1}&f.collection.facet.limit=50&f.place_of_publication.facet.limit=50&f.authorStr.facet.offset=0&f.building.facet.offset=0&all_fields_ps2=2&all_fields_qf=allfieldsProper^2+allfields^1+title_common^50+title_equiv^10+mainauthor^80+author^50+isbn+issn+oclc+lccn+barcode+htid+callnosearch+bookplate&f.format.facet.sort=count&f.publishDateRange.facet.mincount=1&facet=true&f.availability.facet.offset=0
```

## Paths for query_parser_api

```
/catalog/search (this is the url for searching. takes in a bunch of parameters)
/onlinejournals/search (this is the url for searching online journals)
```

```
# Potential path; It's a different solr, but I don't think that matters. It uses the query parser so it ought to go here.
/website.search

# Other catalog paths?
/catalog/record # could make the catalog_api not know how to query solr.
/catalog/debug # show some output for debugging a query
/catalog/solr # send solr queries straight through. Might be useful for super advanced search. 
```

This handles changing the complicated availability filter into something solr/query parser can read.

## Results response

{
  records: []
  filters: []
  total: int
  limit: int
  offset: int
}
