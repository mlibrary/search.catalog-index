from fastapi import FastAPI, HTTPException
from fastapi.middleware.gzip import GZipMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from prometheus_client import Histogram

from catalog_api import schemas
from catalog_api.solr_client import NotFoundError
from catalog_api.record import record_for

app = FastAPI(
    title="Catalog Search API", description="REST API for Catalog Search Solr"
)
app.add_middleware(GZipMiddleware, minimum_size=1000)

Instrumentator().instrument(app).expose(app)

RECORD_HISTOGRAM = Histogram(
    "catalog_api_record_request_duration_seconds",
    "Length of api request for a catalog record",
)


@app.get(
    "/records/{id}",
    responses={
        404: {
            "description": "Bad request: The record was not found",
            "model": schemas.Response404,
        }
    },
    response_model_exclude_none=True,
)
@RECORD_HISTOGRAM.time()
def get_record(id: str) -> schemas.Record:
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
