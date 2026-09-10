from app import app

def test_health():
    client = app.test_client()
    resp = client.get("/api/health")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ok"

def test_products():
    client = app.test_client()
    resp = client.get("/api/products")
    assert resp.status_code == 200
    assert len(resp.get_json()["products"]) == 3
