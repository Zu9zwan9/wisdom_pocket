import asyncio
import json
import types
import os
import sys
import pytest
from fastapi.testclient import TestClient

# Ensure backend package root is on sys.path so `import app` works
CURRENT_DIR = os.path.dirname(__file__)
BACKEND_ROOT = os.path.abspath(os.path.join(CURRENT_DIR, ".."))
if BACKEND_ROOT not in sys.path:
    sys.path.insert(0, BACKEND_ROOT)

from app.main import app


class RedisStub:
    def __init__(self):
        self.store = {}
        self.sets = {}

    async def get(self, k):
        return self.store.get(k)

    async def set(self, k, v, ex=None):
        self.store[k] = v

    async def incr(self, k):
        self.store[k] = str(int(self.store.get(k, "0")) + 1)
        return int(self.store[k])

    async def expire(self, k, ttl):
        return True

    async def smembers(self, k):
        return list(self.sets.get(k, set()))

    async def sadd(self, k, v):
        s = self.sets.setdefault(k, set())
        s.add(str(v))

    async def srem(self, k, v):
        s = self.sets.setdefault(k, set())
        s.discard(str(v))

    async def delete(self, k):
        self.store.pop(k, None)
        self.sets.pop(k, None)


@pytest.fixture(autouse=True)
def patch_redis(monkeypatch):
    redis = RedisStub()

    async def _get_redis():
        return redis

    monkeypatch.setattr("app.redis_client.get_redis", _get_redis)
    yield


def test_health():
    client = TestClient(app)
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_daily_quote():
    client = TestClient(app)
    r = client.get("/v1/quotes/daily")
    assert r.status_code == 200
    body = r.json()
    assert set(body.keys()) == {"id", "text", "author", "category", "is_premium"}


def test_random_quote_premium_toggle():
    client = TestClient(app)
    r = client.get("/v1/quotes/random?premium=false")
    assert r.status_code == 200


def test_auth_and_favorites_and_gdpr_delete():
    client = TestClient(app)
    token = client.post("/v1/auth/login", json={"device_id": "dev123"}).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Add favorite
    client.post("/v1/favorites/1", headers=headers)
    favs = client.get("/v1/favorites/", headers=headers).json()
    assert any(f["id"] == "1" for f in favs)

    # GDPR delete
    r = client.delete("/v1/users/me", headers=headers)
    assert r.status_code == 200
    favs = client.get("/v1/favorites/", headers=headers).json()
    assert favs == []


def test_subscription_mock_and_validate():
    client = TestClient(app)
    token = client.post("/v1/auth/login", json={"device_id": "dev_sub"}).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Validate inactive
    assert client.get("/v1/subscription/validate", headers=headers).json()["active"] is False

    # Mock purchase
    r = client.post("/v1/subscription/mock_purchase", headers=headers)
    assert r.status_code == 200

    # Validate active
    assert client.get("/v1/subscription/validate", headers=headers).json()["active"] is True
