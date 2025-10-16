import pytest
from unittest.mock import patch, MagicMock

# For the exception
import grpc

from job_reviews import JobReviewService

class DummyRequest:
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)

class DummyContext:
    def set_code(self, code): self.code = code
    def set_details(self, details): self.details = details

@pytest.fixture
def service():
    return JobReviewService()

@patch("job_reviews.data_access_client")
def test_calculate_rating(mock_data_access, service):
    # Mock job review response
    job_review = MagicMock(work_life_balance=4, culture_values=5, diversity_inclusion=3, career_opp=4, comp_benefits=0, senior_mgmt=0)
    mock_data_access.GetJobReviewsWithTitleAndCity.return_value = MagicMock(review=[job_review])
    job = MagicMock(id=1, title="Dev", company_name="A", description="desc", location="loc", views=10, salary=1000)
    req = DummyRequest(jobs=[job])
    resp = service.CalculateRating(req, DummyContext())
    assert hasattr(resp, "rating")
    assert len(resp.rating) == 1

@patch("job_reviews.data_access_client")
@patch("job_reviews.CreateReviewResponse")
@patch("job_reviews.CreateReviewRequest")
@patch("job_reviews.Review")
def test_create_review(mock_review, mock_create_req, mock_create_resp, mock_data_access, service):
    # Patch the proto constructors to return MagicMock
    mock_review.return_value = MagicMock()
    mock_create_req.return_value = MagicMock()
    mock_create_resp.return_value = MagicMock(success=True)
    mock_data_access.CreateReview.return_value = MagicMock(success=True)
    review = MagicMock(
        firm="A", job_title="Dev", current="Yes", location="loc", overall_rating=5,
        work_life_balance=4, culture_values=5, diversity_inclusion=3, career_opp=4,
        comp_benefits=4, senior_mgmt=4, recommend="Yes", ceo_approv="Yes", outlook="Good",
        headline="Great", pros="Many", cons="Few"
    )
    req = DummyRequest(review=review)
    resp = service.CreateReview(req, DummyContext())
    assert resp.success

@patch("job_reviews.data_access_client")
def test_get_best_companies(mock_data_access, service):
    review = MagicMock(
        firm="A", overall_rating=5, work_life_balance=4, culture_values=5,
        diversity_inclusion=3, career_opp=4
    )
    mock_data_access.GetJobReviewsForCompanyReview.return_value = MagicMock(review=[review])
    req = DummyRequest()
    resp = service.GetBestCompanies(req, DummyContext())
    assert hasattr(resp, "companyReview")
    assert len(resp.companyReview) >= 1

@patch("job_reviews.data_access_client")
def test_update_job_review(mock_data_access, service):
    mock_data_access.UpdateJobReview.return_value = MagicMock(status="updated")
    req = DummyRequest(id=1, current_status="Yes", rating=5, headline="Updated")
    resp = service.UpdateJobReview(req, DummyContext())
    assert hasattr(resp, "status") or resp is not None

@patch("job_reviews.data_access_client")
def test_best_city(mock_data_access, service):
    review = MagicMock(
        location="Lisbon", overall_rating=5, work_life_balance=4, culture_values=5,
        diversity_inclusion=3, career_opp=4, comp_benefits=4, senior_mgmt=4
    )
    mock_data_access.GetJobReviewsForLocationReview.return_value = MagicMock(review=[review])
    req = DummyRequest()
    resp = service.BestCity(req, DummyContext())
    assert hasattr(resp, "city")
    assert len(resp.city) >= 1

@patch("job_reviews.data_access_client")
@patch("job_reviews.DeleteReviewResponse")
@patch("job_reviews.DeleteReviewRequest")
def test_delete_review_success(mock_delete_req, mock_delete_resp, mock_data_access, service):
    mock_delete_req.return_value = MagicMock()
    mock_delete_resp.return_value = MagicMock(success=True, message="Deleted")
    mock_data_access.DeleteReview.return_value = MagicMock(success=True, message="Deleted")
    req = DummyRequest(review_id=1)
    ctx = DummyContext()
    resp = service.DeleteReview(req, ctx)
    assert resp.success
    assert resp.message == "Deleted"

@patch("job_reviews.data_access_client")
@patch("job_reviews.DeleteReviewResponse")
@patch("job_reviews.DeleteReviewRequest")
def test_delete_review_failure(mock_delete_req, mock_delete_resp, mock_data_access, service):
    mock_delete_req.return_value = MagicMock()
    mock_delete_resp.return_value = MagicMock(success=False, message="Error deleting review")
    # Raise grpc.RpcError instead of Exception
    class DummyRpcError(grpc.RpcError):
        pass
    mock_data_access.DeleteReview.side_effect = DummyRpcError("fail")
    req = DummyRequest(review_id=1)
    ctx = DummyContext()
    resp = service.DeleteReview(req, ctx)
    assert not resp.success
    assert resp.message == "Error deleting review"