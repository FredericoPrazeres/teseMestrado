import pytest
from unittest.mock import patch, MagicMock

from job_postings import JobPostingService

class DummyRequest:
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)

class DummyContext:
    pass

@pytest.fixture
def service():
    return JobPostingService()

@patch("job_postings.data_access_client")
def test_average_salary(mock_data_access, service):
    # Mock response
    job1 = MagicMock(title="Engineer", normalized_salary=100)
    job2 = MagicMock(title="Engineer", normalized_salary=200)
    mock_data_access.GetJobPostingsWithTitle.return_value = MagicMock(job=[job1, job2])
    req = DummyRequest(title="Engineer")
    resp = service.AverageSalary(req, DummyContext())
    assert resp.averageSalary == 150

@patch("job_postings.data_access_client")
@patch("job_postings.job_review_client")
def test_jobs_with_rating(mock_review, mock_data_access, service):
    # Mock job postings
    job = MagicMock(job_id=1, title="Dev", company="A", description="desc", location="loc", views=10, normalized_salary=1000)
    mock_data_access.GetJobPostingsWithTitleAndCity.return_value = MagicMock(job=[job])
    # Mock review response
    rating_job = MagicMock(
        rating=4.5,
        job=MagicMock(
            id=1, title="Dev", company_name="A", description="desc", location="loc", views=10, salary=1000
        )
    )
    mock_review.CalculateRating.return_value = MagicMock(rating=[rating_job])
    req = DummyRequest(title="Dev", city="City")
    resp = service.JobsWithRating(req, DummyContext())
    assert len(resp.jobs) == 1
    assert resp.jobs[0].rating == 4.5

@patch("job_postings.data_access_client")
def test_get_job_postings_for_largest_companies(mock_data_access, service):
    # Mock companies
    company = MagicMock(company_id="1", employee_count=100, company="A")
    mock_data_access.GetCompaniesWithEmployees.return_value = MagicMock(company=[company])
    # Mock job postings
    job = MagicMock(company="A", title="Dev", description="desc", location="loc", company_id="1", med_salary=1000)
    mock_data_access.GetJobPostingsForLargestCompanies.return_value = MagicMock(job=[job])
    req = DummyRequest()
    resp = service.GetJobPostingsForLargestCompanies(req, DummyContext())
    assert len(resp.job) == 1
    assert resp.job[0].company == "A"

@patch("job_postings.data_access_client")
def test_add_job_success(mock_data_access, service):
    mock_data_access.PostJobInDB.return_value = MagicMock(status=200)
    req = DummyRequest(
        title="Dev", company_name="A", description="desc", location="loc", normalized_salary=1000
    )
    resp = service.AddJob(req, DummyContext())
    assert resp.status == 201

@patch("job_postings.data_access_client")
def test_add_job_missing_fields(mock_data_access, service):
    req = DummyRequest(
        title="", company_name="", description="", location="", normalized_salary=None
    )
    resp = service.AddJob(req, DummyContext())
    assert resp.status == 400

@patch("job_postings.data_access_client")
def test_get_remote_jobs(mock_data_access, service):
    job = MagicMock(id=1, title="Remote", company="A", description="desc", location="loc", remote_allowed=True)
    mock_data_access.GetRemoteJobs.return_value = MagicMock(jobs=[job])
    req = DummyRequest(city="City", keyword="Remote", company="A")
    resp = service.GetRemoteJobs(req, DummyContext())
    assert len(resp.jobs) == 1
    assert resp.jobs[0].remote_allowed

@patch("job_postings.data_access_client")
def test_get_best_paying_companies(mock_data_access, service):
    company = MagicMock(company_name="A", average_salary=1000)
    mock_data_access.GetBestPayingCompanies.return_value = MagicMock(companies=[company])
    req = DummyRequest(title="Dev")
    resp = service.GetBestPayingCompanies(req, DummyContext())
    assert len(resp.companies) == 1
    assert resp.companies[0]["company_name"] == "A"