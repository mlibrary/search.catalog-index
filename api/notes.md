# Notes for Search Results

## Example solr params for faceted search
```json
{
  "f.authorStr.facet.mincount": "1",
  "df": "allfields",
  "f.authorStr.facet.sort": "count",
  "f.hlb3Str.facet.offset": "0",
  "f.publishDateRange.facet.limit": "500",
  "qq1": "\"something\"",
  "tie": "0.1",
  "f.institution.facet.sort": "count",
  "f.building.facet.mincount": "1",
  "f.hlb3Str.facet.sort": "count",
  "f.topicStr.facet.sort": "count",
  "f.authorStr.facet.limit": "500",
  "f.language.facet.sort": "count",
  "f.format.facet.limit": "500",
  "f.topicStr.facet.limit": "500",
  "f.building.facet.sort": "count",
  "qq": "\"_query_\\:\\{\\!edismax mm=$default_mm mm.autoRelax=$mm.autoRelax tie=$tie qf=$all_fields_qf pf=$all_fields_pf pf2=$all_fields_pf2 ps2=$all_fields_ps2 boost=$all_fields_boost v=$q1\\}\"",
  "per_page": "30",
  "f.search_only.facet.offset": "0",
  "f.search_only.facet.mincount": "1",
  "qt": "standard",
  "f.building.facet.limit": "500",
  "f.institution.facet.limit": "500",
  "sort": "score desc",
  "f.availability.facet.limit": "500",
  "f.search_only.facet.sort": "count",
  "default_mm": "2<-1 5<67%",
  "f.geographicStr.facet.limit": "500",
  "mm.autoRelax": "true",
  "f.institution.facet.offset": "0",
  "f.hlb3Str.facet.mincount": "1",
  "f.geographicStr.facet.mincount": "1",
  "f.format.facet.offset": "0",
  "f.place_of_publication.facet.offset": "0",
  "f.topicStr.facet.mincount": "1",
  "page": "1",
  "t1": "something",
  "f.place_of_publication.facet.mincount": "1",
  "f.language.facet.mincount": "1",
  "f.availability.facet.mincount": "1",
  "f.language.facet.offset": "0",
  "all_fields_pf2": "title_author^500 title_equiv^80 title_l^50",
  "fl": "*,score",
  "f.location.facet.mincount": "1",
  "f.publishDateRange.facet.offset": "0",
  "f.language.facet.limit": "500",
  "fq": [
    "format:(Music)",
    "institution:(UM\\ Ann\\ Arbor\\ Libraries)",
    "+(new_availability:physical OR new_availability:hathi_trust_full_text_or_electronic_holding)"
  ],
  "f.location.facet.sort": "count",
  "f.publishDateRange.facet.sort": "count",
  "all_fields_pf": "title_equiv^40 title_top^20 itle_rest^10 author^80 author_top^30 author_rest^20",
  "f.format.facet.mincount": "1",
  "f.hlb3Str.facet.limit": "500",
  "f.geographicStr.facet.sort": "count",
  "f.institution.facet.mincount": "1",
  "facet.threads": "10",
  "clean_string": "something",
  "wt": "json",
  "f.search_only.facet.limit": "500",
  "f.topicStr.facet.offset": "0",
  "f.location.facet.offset": "0",
  "q1": "something",
  "facet.field": [
    "search_only",
    "availability",
    "format",
    "topicStr",
    "publishDateRange",
    "language",
    "location",
    "hlb3Str",
    "authorStr",
    "place_of_publication",
    "geographicStr",
    "institution",
    "building"
  ],
  "f.place_of_publication.facet.sort": "count",
  "f.geographicStr.facet.offset": "0",
  "start": "0",
  "rows": "30",
  "all_fields_boost": "product( if(termfreq(format, Journal), 1.4, 1), max( map( query({!field f=title_common_exact v=$q1}, 1), 0, 1, 1, 180 ), map( query({!field f=title_equiv_exact v=$q1}, 1), 0, 1, 1, 50 ), map( query({!field f=title_a_exact v=$q1}, 1), 0, 1, 1, 10 )), map( query({!dismax f=title_author v=$q1 mm=\"100%\"}, 1), 0, 1, 1, 50 ), )",
  "f.availability.facet.sort": "count",
  "q": "_query_:{!edismax mm=$default_mm mm.autoRelax=$mm.autoRelax tie=$tie qf=$all_fields_qf pf=$all_fields_pf pf2=$all_fields_pf2 ps2=$all_fields_ps2 boost=$all_fields_boost v=$q1}",
  "f.location.facet.limit": "500",
  "f.place_of_publication.facet.limit": "500",
  "f.authorStr.facet.offset": "0",
  "f.building.facet.offset": "0",
  "all_fields_ps2": "2",
  "all_fields_qf": "allfieldsProper^2 allfields^1 title_common^50 title_equiv^10 mainauthor^80 author^50 isbn issn oclc lccn barcode htid callnosearch bookplate",
  "f.format.facet.sort": "count",
  "f.publishDateRange.facet.mincount": "1",
  "facet": "true",
  "f.availability.facet.offset": "0"
}
```

## Example query for plain search

```
{
  "all_fields_mm": "25%",
  "df": "allfields",
  "f.og_groups_both.facet.offset": "0",
  "f.search_title_starts_with.qf": "title_ngram",
  "f.search_isn.qf": "issn",
  "f.category.facet.sort": "count",
  "f.smfield_access_type.facet.limit": "500",
  "f.new.facet.sort": "count",
  "qq1": "\"something\"",
  "tie": "0.1",
  "f.title_starts_with.mm": "100%",
  "f.search_isn.mm": "100%",
  "f.title_initial.facet.offset": "0",
  "qf": "title_unstemmed^10 title^7 all_titles_unstemmed^8 all_titles^6 issn^10 content^2",
  "f.search_title_starts_with.mm": "100%",
  "f.search_publisher.pf": "pvc_text",
  "f.search_title.pf": "title alt",
  "f.mobile.facet.limit": "500",
  "mm": "25%",
  "qq": "\"_query_\\:\\{\\!edismax mm=$all_fields_mm mm.autoRelax=$mm.autoRelax tie=$tie qf=$all_fields_qf pf=$all_fields_pf v=$q1\\}\"",
  "per_page": "10",
  "f.search_academic_discipline.mm": "50%",
  "qt": "edismax",
  "f.title_starts_with.qf": "title_ngram",
  "f.search_isn.pf": "issn",
  "f.title_initial.facet.sort": "count",
  "sort": "score desc",
  "f.smfield_access_type.facet.offset": "0",
  "f.category.facet.offset": "0",
  "f.category.facet.mincount": "1",
  "f.search_publisher.qf": "pvc_text",
  "page": "1",
  "f.new.facet.offset": "0",
  "f.search_academic_discipline.qf": "og_groups_both^5 tmfield_taxonomy_name",
  "t1": "something",
  "f.search_publisher.mm": "50%",
  "f.academic_discipline.qf": "og_groups_both^5 tmfield_taxonomy_name",
  "f.title_starts_with.pf": "title_ngram",
  "fl": "*,score",
  "f.smfield_access_type.facet.mincount": "1",
  "f.search_title.mm": "75%",
  "f.academic_discipline.mm": "50%",
  "f.og_groups_both.facet.mincount": "1",
  "fq": [
    "+source:searchtools-drupal",
    "+status:true"
  ],
  "f.mobile.facet.offset": "0",
  "defType": "edismax",
  "all_fields_pf": "title all_titles content",
  "f.og_groups_both.facet.limit": "500",
  "f.new.facet.limit": "500",
  "f.title_initial.facet.limit": "500",
  "clean_string": "something",
  "f.mobile.facet.sort": "count",
  "f.search_academic_discipline.pf": "og_groups_both^5 tmfield_taxonomy_name",
  "wt": "json",
  "f.new.facet.mincount": "1",
  "f.search_title_starts_with.pf": "title_ngram",
  "q1": "something",
  "f.mobile.facet.mincount": "1",
  "f.smfield_access_type.facet.sort": "count",
  "facet.field": [
    "og_groups_both",
    "smfield_access_type",
    "category",
    "title_initial",
    "mobile",
    "new"
  ],
  "f.academic_discipline.pf": "og_groups_both^5 tmfield_taxonomy_name",
  "start": "0",
  "rows": "10",
  "q": "_query_:{!edismax mm=$all_fields_mm mm.autoRelax=$mm.autoRelax tie=$tie qf=$all_fields_qf pf=$all_fields_pf v=$q1}",
  "f.title_initial.facet.mincount": "1",
  "f.category.facet.limit": "500",
  "f.og_groups_both.facet.sort": "count",
  "pf": "title all_titles content",
  "f.search_title.qf": "sort_title^12 stitle^12 title_unstemmed^6 all_titles_unstemmed^3 title^2 alt^1",
  "all_fields_qf": "title_unstemmed^10 title^7 all_titles_unstemmed^8 all_titles^6 issn^10 content^2",
  "facet": "true"
}
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
