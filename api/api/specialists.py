import requests
from api.services import S
from api.results import CatalogFilterQuery, solr_escape, CatalogResults


def get_specialists(query_params: dict):
    catalog_response = fetch_academic_disciplines(query_params)

    top_academic_disciplines = get_top_academic_disciplines(catalog_response)

    website_response = fetch_website_solr_specialists(
        website_solr_query_params(top_academic_disciplines, query_params)
    )
    specialists = specialist_response(website_response)
    return {
        "specialists": specialists,
        "academic_disciplines": top_academic_disciplines,
    }


def fetch_academic_disciplines(query_params: dict):
    fq = CatalogFilterQuery(query_params)
    parser_params = {
        "query": query_params["query"],
        "fq[]": fq.query(),
        "sort": CatalogResults.sort_map[query_params["sort"]],
    }
    response = requests.Session().get(
        f"{S.parser_url}/catalog/academic_disciplines", params=parser_params
    )
    return response.json()


def specialist_response(data):
    specialists = []
    for person in data["response"]["docs"]:
        specialists.append(
            {
                "name": person["title"],
                "uniqname": person["ssfield_uniqname"],
                "title": person.get("job_title", None),
                "email": person["email"][0],
                "phone": person.get("ssfield_phone", None),
                "academic_disciplines": person["taxonomy_name"],
            }
        )
    return specialists


def website_solr_query_params(top_academic_disciplines, query_params):
    fq_academic_disciplines = []
    for f in query_params.get("filters", []):
        term, value = f.split(":")
        if term == "academic_discipline":
            fq_academic_disciplines.append(solr_escape(value))

    fq = "+source:drupal-users +status:true"
    if fq_academic_disciplines:
        ad_str = " AND ".join(fq_academic_disciplines)
        fq += f" +(taxonomy_name:({ad_str}))"

    query = " OR ".join([tad["discipline"] for tad in top_academic_disciplines])

    bq = [
        f"taxonomy_name:({tad['discipline']})^{tad['count']}"
        for tad in top_academic_disciplines
    ]

    return {
        "mm": 1,
        "qf": "taxonomy_name",
        "pf": "taxonomy_name",
        "q": query,
        "fq": fq,
        "bq": bq,
        "rows": 10,
        "defType": "edismax",
        "fl": "*",
        "wt": "json",
    }


def fetch_website_solr_specialists(params):
    resp = requests.Session().get(
        f"{S.website_solr_url}/solr/www.lib/select", params=params
    )
    return resp.json()


def get_top_academic_disciplines(data: dict):
    term_threshold = 25
    term_counts = {}
    for doc in data["response"]["docs"]:
        if "hlb3Str" in doc:
            for term in doc["hlb3Str"]:
                if term in term_counts:
                    term_counts[term] += 1
                else:
                    term_counts[term] = 1

    result = []
    for term in term_counts:
        if term_counts[term] >= term_threshold:
            result.append({"discipline": solr_escape(term), "count": term_counts[term]})
    return result
