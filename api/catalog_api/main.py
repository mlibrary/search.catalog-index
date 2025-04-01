from fastapi import FastAPI
from catalog_api import schemas
from catalog_api.record import record_for

app = FastAPI(
    title="Catalog Search API", description="REST API for Catalog Search Solr"
)


@app.get("/records/{id}")
def get_record(id: str) -> schemas.Record:
    """
    Gets a record from catalog solr. The Item is fetched by the solr id, which
    is the mms_id for an Alma record or a htid with a 11 prefix for a HathiTrust
    record
    """

    return record_for(id)
