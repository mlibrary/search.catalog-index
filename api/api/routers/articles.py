from typing import Annotated
from fastapi import APIRouter, HTTPException, Query
from api.metrics import REQUEST_HISTOGRAM
from api import schemas
from api.exlibris_client import NotFoundError
from api.primo import record_for

router = APIRouter(prefix="/articles", tags=["articles"])


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
@REQUEST_HISTOGRAM.labels(datastore="articles", route="record").time()
def get_record(id: str) -> schemas.ArticlesRecord:
    """
    Gets a record from catalog solr. The record is fetched by the solr id, which
    is the mms_id for an Alma record or a htid with a 11 prefix for a HathiTrust
    record
    """
    try:
        result = record_for(id)
        return result
    except NotFoundError:
        raise HTTPException(status_code=404, detail="Item not found")
