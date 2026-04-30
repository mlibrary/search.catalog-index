from fastapi import FastAPI
from fastapi.middleware.gzip import GZipMiddleware
from prometheus_fastapi_instrumentator import Instrumentator

from .routers import catalog

app = FastAPI(
    title="Catalog Search API", description="REST API for Catalog Search Solr"
)
app.add_middleware(GZipMiddleware, minimum_size=1000)
app.include_router(catalog.router)

Instrumentator().instrument(app).expose(app)
