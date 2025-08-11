from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response
from loguru import logger
import sentry_sdk

from .config import settings
from .routers import health, quotes, auth, users, favorites, subscription

REQUEST_COUNT = Counter('wp_http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'http_status'])


def _init_sentry():
    if settings.SENTRY_DSN:
        sentry_sdk.init(dsn=settings.SENTRY_DSN, traces_sample_rate=0.0)
        logger.info("Sentry initialized")
    else:
        logger.info("Sentry DSN not set; skipping Sentry initialization")


app = FastAPI(title="Wisdom Pocket API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    response = await call_next(request)
    try:
        REQUEST_COUNT.labels(request.method, request.url.path, str(response.status_code)).inc()
    except Exception:
        pass
    return response


@app.on_event("startup")
async def on_startup():
    _init_sentry()
    logger.info("Wisdom Pocket API starting in {} mode", settings.ENV)


@app.get(settings.PROMETHEUS_PATH)
async def metrics():
    data = generate_latest()
    return Response(content=data, media_type=CONTENT_TYPE_LATEST)


app.include_router(health.router)
app.include_router(auth.router, prefix="/v1")
app.include_router(quotes.router, prefix="/v1")
app.include_router(favorites.router, prefix="/v1")
app.include_router(users.router, prefix="/v1")
app.include_router(subscription.router, prefix="/v1")
