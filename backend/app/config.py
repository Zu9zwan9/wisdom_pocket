import os
from datetime import timedelta


class Settings:
    ENV: str = os.getenv("ENV", "development")
    BACKEND_HOST: str = os.getenv("BACKEND_HOST", "0.0.0.0")
    BACKEND_PORT: int = int(os.getenv("BACKEND_PORT", "8000"))

    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql+asyncpg://wp_user:wp_password@postgres:5432/wisdom_pocket",
    )
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://redis:6379/0")
    JWT_SECRET: str = os.getenv("JWT_SECRET", "dev_secret_change_me")
    JWT_ALG: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "43200"))  # 30 days

    RATE_LIMIT_PER_MINUTE: int = int(os.getenv("RATE_LIMIT_PER_MINUTE", "60"))

    SENTRY_DSN: str | None = os.getenv("SENTRY_DSN")

    USE_REVENUECAT_MOCK: bool = os.getenv("USE_REVENUECAT_MOCK", "true").lower() == "true"
    REVENUECAT_SECRET: str = os.getenv("REVENUECAT_SECRET", "mock_secret")

    PROMETHEUS_PATH: str = "/metrics"

    QUOTES_FILE: str = os.getenv(
        "QUOTES_FILE",
        os.path.join(os.path.dirname(__file__), "data", "sample_quotes.json"),
    )

    DAILY_CACHE_TTL: int = int(timedelta(hours=23).total_seconds())


settings = Settings()
