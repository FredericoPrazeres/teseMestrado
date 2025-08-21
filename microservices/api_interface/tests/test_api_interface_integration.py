import requests

API_URL = "http://localhost:8082"

def test_jobs_remote_payload():
    params = {"title": "Engineer", "city": "New York"}
    resp = requests.get(f"{API_URL}/jobs/search/remote", params=params, timeout=5)
    assert resp.status_code == 200
    assert "jobs" in resp.json()
