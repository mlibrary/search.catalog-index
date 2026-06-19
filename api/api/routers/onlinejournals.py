from typing import Annotated
from fastapi import APIRouter, HTTPException, Query
from prometheus_client import Histogram
from api import schemas
from api.solr_client import NotFoundError
from api.record import onlinejournals_record_for
from api.results import get_results
from api import specialists

router = APIRouter(prefix="/onlinejournals", tags=["onlinejournals"])

# RECORD_HISTOGRAM = Histogram(
# "catalog_record_request_duration_seconds",
# "Length of api request for a catalog record",
# )


@router.get(
    "/records/{id}",
    responses={
        404: {
            "description": "Bad request: The record was not found",
            "model": schemas.Response404,
        }
    },
    response_model_exclude_none=True,
)
# @RECORD_HISTOGRAM.time()
def get_record(id: str) -> schemas.OnlinejournalsRecord:
    """
    Gets a record from catalog solr. The record is fetched by the solr id, which
    is the mms_id for an Alma record or a htid with a 11 prefix for a HathiTrust
    record
    """
    try:
        result = onlinejournals_record_for(id)
        return result
    except NotFoundError:
        raise HTTPException(status_code=404, detail="Item not found")


@router.get("/search", response_model_exclude_none=True)
def get_search_results(
    query: str = "",
    offset: int = 0,
    limit: int = 10,
    filters: Annotated[list[str], Query()] = [],
    ht_search_only: bool = False,
    sort: schemas.Sort = schemas.Sort.relevance,
) -> schemas.Results:
    """
    Does a search in catalog solr
    """
    results = get_results(
        {
            "query": query,
            "offset": offset,
            "limit": limit,
            "filters": filters,
            "ht_search_only": ht_search_only,
            "sort": sort,
        }
    )
    return results


@router.get("/specialists", response_model_exclude_none=True)
def get_specialists(
    query: str = "",
    filters: Annotated[list[str], Query()] = [],
    ht_search_only: bool = False,
    sort: schemas.Sort = schemas.Sort.relevance,
) -> schemas.Specialists:
    """
    Looks up specialists associated with given query
    """
    results = specialists.get_specialists(
        {
            "query": query,
            "filters": filters,
            "ht_search_only": ht_search_only,
            "sort": sort,
        }
    )
    return results
