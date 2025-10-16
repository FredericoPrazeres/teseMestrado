import pytest
from unittest.mock import patch, MagicMock
from api_interface import app

@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client

@patch("api_interface.job_postings_client")
def test_average_salary(mock_job_postings,client):
    mock_job_postings.AverageSalary.return_value = MagicMock(averageSalary=1234)
    resp = client.get("/jobs/search/average-salary?title=Engineer")
    assert resp.status_code == 200
    assert resp.json["averageSalary"] == 1234

@patch("api_interface.job_reviews_client")
def test_best_cities(mock_job_reviews, client):
    city = MagicMock(city="Lisbon", average_rating=4.5)
    mock_job_reviews.BestCity.return_value = MagicMock(city=[city])
    resp = client.get("/jobs/search/best-cities")
    assert resp.status_code == 200
    assert resp.json["cities"][0]["name"] == "Lisbon"

@patch("api_interface.job_postings_client")
def test_add_job(mock_job_postings, client):
    mock_job_postings.AddJob.return_value = MagicMock(message="Added", status=201)
    data = {
        "title": "Dev", "normalized_salary": 1000, "company_name": "A",
        "description": "desc", "location": "loc"
    }
    resp = client.post("/jobs/post/job-posting", json=data)
    assert resp.status_code == 201
    assert resp.json["job_response"]["message"] == "Added"

@patch("api_interface.job_postings_client")
def test_jobs_with_rating(mock_job_postings, client):
    job = MagicMock()
    job.job.title = "Dev"
    job.job.company_name = "A"
    job.job.salary = 1000
    job.job.location = "loc"
    job.job.views = 10
    job.rating = 4.5
    job.job.description = "desc"
    mock_job_postings.JobsWithRating.return_value = MagicMock(jobs=[job])
    resp = client.get("/jobs/search/jobs-with-rating?title=Dev&city=Lisbon")
    assert resp.status_code == 200
    assert resp.json["jobs"][0]["title"] == "Dev"

@patch("api_interface.job_reviews_client")
def test_add_job_review(mock_job_reviews, client):
    mock_job_reviews.CreateReview.return_value = MagicMock(success=True)
    data = {
        "firm": "A", "job_title": "Dev", "location": "loc", "overall_rating": 5,
        "pros": "Good", "cons": "None"
    }
    resp = client.post("/jobs/post/review-posting", json=data)
    assert resp.status_code == 200
    assert resp.json["success"]

@patch("api_interface.job_reviews_client")
def test_best_companies(mock_job_reviews, client):
    company = MagicMock(
        firm="A", overall_rating=5, work_life_balance=4, culture_values=5,
        diversity_inclusion=3, career_opp=4
    )
    mock_job_reviews.GetBestCompanies.return_value = MagicMock(companyReview=[company])
    resp = client.get("/jobs/search/best-companies")
    assert resp.status_code == 200
    assert resp.json["bestCompanies"][0]["firm"] == "A"

@patch("api_interface.job_postings_client")
def test_jobs_for_largest_companies(mock_job_postings, client):
    job = MagicMock(
        company="A", title="Dev", description="desc", location="loc", company_id=1, med_salary=1000
    )
    mock_job_postings.GetJobPostingsForLargestCompanies.return_value = MagicMock(job=[job])
    resp = client.get("/jobs/search/jobs-in-biggest-companies")
    assert resp.status_code == 200
    assert resp.json["jobs"][0]["company"] == "A"

@patch("api_interface.job_reviews_client")
def test_update_review(mock_job_reviews, client):
    mock_job_reviews.UpdateJobReview.return_value = MagicMock()
    data = {"id": 1, "rating": 5, "headline": "Updated", "current_status": "Yes"}
    resp = client.put("/jobs/put/review-update", json=data)
    assert resp.status_code == 200
    assert resp.json["success"]

@patch("api_interface.job_postings_client")
def test_remote_jobs(mock_job_postings, client):
    job = MagicMock(
        id=1, company="A", title="Remote", description="desc", location="loc", remote_allowed=True
    )
    mock_job_postings.GetRemoteJobs.return_value = MagicMock(jobs=[job])
    resp = client.get("/jobs/search/remote?company=A")
    assert resp.status_code == 200
    assert resp.json["jobs"][0]["remote_allowed"]

@patch("api_interface.job_postings_client")
def test_best_paying_companies(mock_job_postings, client):
    company = MagicMock(company_name="A", average_salary=1000)
    mock_job_postings.GetBestPayingCompanies.return_value = MagicMock(companies=[company])
    resp = client.get("/jobs/search/best-paying-companies?title=Dev")
    assert resp.status_code == 200
    assert resp.json["best_paying_companies"][0]["company_name"] == "A"

@patch("api_interface.job_reviews_client")
def test_delete_job_review(mock_job_reviews, client):
    mock_job_reviews.DeleteReview.return_value = MagicMock(success=True, message="Deleted")
    resp = client.delete("/jobs/delete/review-deletion?review_id=1")
    assert resp.status_code == 200
    assert resp.json["Response"][0]["success"]