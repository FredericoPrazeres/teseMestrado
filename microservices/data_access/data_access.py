#!/usr/bin/env python3
import psycopg2
import psycopg2.extras

import random, os
from concurrent import futures
import grpc
import data_access_pb2
import data_access_pb2_grpc
import data_access_pb2
from grpc_interceptor import ExceptionToStatusInterceptor
from grpc_interceptor.exceptions import NotFound
from data_access_pb2 import Job, Review, JobForLargestCompany, BestCompany, BestPayingCompaniesResponse, DeleteReviewResponse, RemoteJobSearchResponse, JobForRemote, JobPostingsResponse, JobReviewsResponse, CompaniesResponse, UpdateJobReviewResponse, JobPostingsForLargestCompaniesResponse, CreateReviewResponse, PostJobResponse

DB_CONFIG = {
    "dbname": "mydatabase",
    "user": "myuser",
    "password": "mypassword",
    "host": "postgres_db",  # Docker service name
    "port": "5432"
}

class DataAccessService(data_access_pb2_grpc.DataAccessServiceServicer):
    def GetJobPostingsWithTitle(self, request, context):
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
            cursor.execute("SELECT * FROM jobs WHERE title LIKE %s", (f"%{request.title}%",))
            rows = cursor.fetchall()

            # Transform rows into Job objects.
            job_postings = [
                Job(
                    job_id=row["job_id"],
                    company=row["company"],
                    title=row["title"],
                    description=row["description"],
                    max_salary=row["max_salary"] or 0.0,
                    pay_period=row["pay_period"],
                    location=row["location"],
                    company_id=row["company_id"] or 0.0,
                    views=row["views"] or 0.0,
                    med_salary=row["med_salary"] or 0.0,
                    min_salary=row["min_salary"] or 0.0,
                    formatted_work_type=row["formatted_work_type"],
                    remote_allowed=row["remote_allowed"],
                    job_posting_url=row["job_posting_url"],
                    aplication_url=row["aplication_url"],
                    application_type=row["application_type"],
                    formatted_experience_level=row["formatted_experience_level"],
                    skills_desc=row["skills_desc"],
                    posting_domain=row["posting_domain"],
                    sponsored=row["sponsored"],
                    work_type=row["work_type"],
                    currency=row["currency"],
                    normalized_salary=row["normalized_salary"] or 0.0,
                    zip_code=row["zip_code"] or 0.0
                )
                for row in rows
            ]
            cursor.close()
            conn.close()

            return JobPostingsResponse(job=job_postings)
        except Exception as e:
            return JobPostingsResponse(job=[])
        
    def GetJobPostingsWithTitleAndCity(self, request, context):
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
            cursor.execute("SELECT * FROM jobs WHERE title LIKE %s AND location LIKE %s", (f"%{request.title}%", f"%{request.city}%",))
            rows = cursor.fetchall()

            job_postings = [
                Job(
                    job_id=row["job_id"],
                    company=row["company"],
                    title=row["title"],
                    description=row["description"],
                    max_salary=row["max_salary"] or 0.0,
                    pay_period=row["pay_period"],
                    location=row["location"],
                    company_id=row["company_id"] or 0.0,
                    views=row["views"] or 0.0,
                    med_salary=row["med_salary"] or 0.0,
                    min_salary=row["min_salary"] or 0.0,
                    formatted_work_type=row["formatted_work_type"],
                    remote_allowed=row["remote_allowed"],
                    job_posting_url=row["job_posting_url"],
                    aplication_url=row["aplication_url"],
                    application_type=row["application_type"],
                    formatted_experience_level=row["formatted_experience_level"],
                    skills_desc=row["skills_desc"],
                    posting_domain=row["posting_domain"],
                    sponsored=row["sponsored"],
                    work_type=row["work_type"],
                    currency=row["currency"],
                    normalized_salary=row["normalized_salary"] or 0.0,
                    zip_code=row["zip_code"] or 0.0
                )
                for row in rows
            ]

            cursor.close()
            conn.close()

            return JobPostingsResponse(job=job_postings)

        except Exception as e:
            print(f"Database error: {e}")
            return JobPostingsResponse(job=[])

    def GetJobPostingsForLargestCompanies(self, request, context):
        try:
            # Connect to the database.
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
            
            # Execute the SQL query.
            query = (
                "SELECT company, title, description, location, company_id, med_salary "
                "FROM jobs WHERE company_id = %s LIMIT %s OFFSET %s"
            )
            params = (request.company_id, request.limit, request.offset)
            cursor.execute(query, params)
            
            # Fetch the results.
            rows = cursor.fetchall()
            
            # Transform rows into JobForLargestCompany objects.
            job_postings = []
            for idx, row in enumerate(rows):
                job_obj = JobForLargestCompany(
                    company=row["company"],
                    title=row["title"],
                    description=row["description"],
                    location=row["location"],
                    company_id=int(row["company_id"]) if row["company_id"] is not None else 0,
                    med_salary=float(row["med_salary"]) if row["med_salary"] is not None else 0.0
                )
                job_postings.append(job_obj)
            
            # Close the cursor and connection.
            cursor.close()
            conn.close()
            
            return JobPostingsForLargestCompaniesResponse(job=job_postings)
        except Exception as e:
            return JobPostingsForLargestCompaniesResponse(job=[])

    def GetCompaniesWithEmployees(self, request, context):
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
            cursor.execute("SELECT * FROM employee;")
            rows = cursor.fetchall()
            
            company = [
                data_access_pb2.Company(
                    company_id=row["company_id"] if row["company_id"] is not None else 0,
                    employee_count=row["employee_count"] if row["employee_count"] is not None else 0,
                    follower_count=row["follower_count"] if row["follower_count"] is not None else 0,
                )
                for row in rows
            ]
            cursor.close()
            conn.close()
            return CompaniesResponse(company=company)
        except Exception as e:
            return CompaniesResponse(company=[])

    def GetJobReviewsForCompanyReview(self, request, context):
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
            cursor.execute(
                "SELECT * FROM reviews LIMIT %s OFFSET %s", 
                (request.limit, request.offset)
            )
            rows = cursor.fetchall()
            
            reviews = [
                data_access_pb2.Review(
                    firm=row["firm"],
                    overall_rating=row["overall_rating"] if row["overall_rating"] is not None else 0,
                    work_life_balance=row["work_life_balance"] if row["work_life_balance"] is not None else 0.0,
                    culture_values=row["culture_values"] if row["culture_values"] is not None else 0.0,
                    diversity_inclusion=row["diversity_inclusion"] if row["diversity_inclusion"] is not None else 0.0,
                    career_opp=row["career_opp"] if row["career_opp"] is not None else 0.0,
                )
                for row in rows
            ]
            cursor.close()
            conn.close()
            return JobReviewsResponse(review=reviews)
        except Exception as e:
            return JobReviewsResponse(review=[])
    def GetJobReviewsForLocationReview(self, request, context):
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
            cursor.execute(
                "SELECT * FROM reviews LIMIT %s OFFSET %s", 
                (request.limit, request.offset)
            )
            rows = cursor.fetchall()
            
            reviews = [
                Review(
                    location=row["location"],
                    overall_rating=row["overall_rating"] if row["overall_rating"] is not None else 0,
                    work_life_balance=row["work_life_balance"] if row["work_life_balance"] is not None else 0.0,
                    culture_values=row["culture_values"] if row["culture_values"] is not None else 0.0,
                    diversity_inclusion=row["diversity_inclusion"] if row["diversity_inclusion"] is not None else 0.0,
                    career_opp=row["career_opp"] if row["career_opp"] is not None else 0.0,
                    comp_benefits=row["comp_benefits"] if row["comp_benefits"] is not None else 0.0,
                    senior_mgmt=row["senior_mgmt"] if row["senior_mgmt"] is not None else 0.0,
                )
                for row in rows
            ]
            cursor.close()
            conn.close()
            return JobReviewsResponse(review=reviews)
        except Exception as e:
            return JobReviewsResponse(review=[])

    def UpdateJobReview(self, request, context):
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
            
            update_query = """
                UPDATE reviews
                SET current = %s,
                    overall_rating = %s,
                    headline = %s
                WHERE id = %s
            """
            cursor.execute(update_query, (request.current_status, request.rating, request.headline, request.id))
            conn.commit()
            rowcount = cursor.rowcount
            cursor.close()
            conn.close()
            
            if rowcount == 0:
                return UpdateJobReviewResponse(success=False, message="Review not found")
            else:
                return UpdateJobReviewResponse(success=True, message="Review updated successfully")
        except Exception as e:
            return UpdateJobReviewResponse(success=False, message=str(e))
        
    def GetJobReviewsWithTitleAndCity(self, request, context):
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)  # Permite acessar colunas pelo nome
            cursor.execute(
                "SELECT * FROM reviews WHERE TRIM(job_title) LIKE %s AND TRIM(location) LIKE %s",
                (f"%{request.title}%", f"%{request.city}%",)
            )
            rows = cursor.fetchall()
            reviews = [
                # Assuming 'Review' is defined in data_access_pb2; adjust import if necessary.
                # If not, you might need to import it similarly to Job.
                # For this example, we're assuming the same module defines Review.
                Review(
                    id=row["id"],
                    firm=row["firm"],
                    job_title=row["job_title"],
                    current=row["current"],
                    location=row["location"],
                    overall_rating=row["overall_rating"] if row["overall_rating"] is not None else 0,
                    work_life_balance=row["work_life_balance"] if row["work_life_balance"] is not None else 0.0,
                    culture_values=row["culture_values"] if row["culture_values"] is not None else 0.0,
                    diversity_inclusion=row["diversity_inclusion"] if row["diversity_inclusion"] is not None else 0.0,
                    career_opp=row["career_opp"] if row["career_opp"] is not None else 0.0,
                    comp_benefits=row["comp_benefits"] if row["comp_benefits"] is not None else 0.0,
                    senior_mgmt=row["senior_mgmt"] if row["senior_mgmt"] is not None else 0.0,
                    recommend=row["recommend"],
                    ceo_approv=row["ceo_approv"],
                    outlook=row["outlook"],
                    headline=row["headline"],
                    pros=row["pros"],
                    cons=row["cons"]
                )
                for row in rows
            ]

            cursor.close()
            conn.close()

            return JobReviewsResponse(review=reviews)

        except Exception as e:
            print(f"Database error: {e}")
            return JobReviewsResponse(review=[])
        
    def CreateReview(self, request, context):
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor()

            cursor.execute("SELECT COALESCE(MAX(id), 0) + 1 FROM reviews")
            next_id = cursor.fetchone()[0]

            review_data = {
                "id": next_id,
                "firm": request.review.firm or "",
                "job_title": request.review.job_title or "",
                "current": request.review.current or "",
                "location": request.review.location or "",
                "overall_rating": request.review.overall_rating or None,
                "work_life_balance": request.review.work_life_balance or None,
                "culture_values": request.review.culture_values or None,
                "diversity_inclusion": request.review.diversity_inclusion or None,
                "career_opp": request.review.career_opp or None,
                "comp_benefits": request.review.comp_benefits or None,
                "senior_mgmt": request.review.senior_mgmt or None,
                "recommend": request.review.recommend or "",
                "ceo_approv": request.review.ceo_approv or "",
                "outlook": request.review.outlook or "",
                "headline": request.review.headline or "",
                "pros": request.review.pros or "",
                "cons": request.review.cons or ""
            }

            cursor.execute("""
                INSERT INTO reviews (
                    id, firm, job_title, current, location, overall_rating, 
                    work_life_balance, culture_values, diversity_inclusion, 
                    career_opp, comp_benefits, senior_mgmt, recommend, 
                    ceo_approv, outlook, headline, pros, cons
                ) VALUES (
                    %(id)s, %(firm)s, %(job_title)s, %(current)s, %(location)s, %(overall_rating)s, 
                    %(work_life_balance)s, %(culture_values)s, %(diversity_inclusion)s, 
                    %(career_opp)s, %(comp_benefits)s, %(senior_mgmt)s, %(recommend)s, 
                    %(ceo_approv)s, %(outlook)s, %(headline)s, %(pros)s, %(cons)s
                )
            """, review_data)

            conn.commit()
            cursor.close()
            conn.close()

            return CreateReviewResponse(success="Review added successfully.")
        except Exception as e:
            print(f"Database error: {e}")
            return CreateReviewResponse(success="Failed to add review.")
        
    def PostJobInDB(self, request, context):
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor()

            job_id = self.generate_unique_job_id(cursor)

            cursor.execute("""
                INSERT INTO jobs (job_id, title, company, description, location, normalized_salary)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (
                job_id,
                request.title,
                request.company_name,
                request.description,
                request.location,
                request.normalized_salary,
            ))

            # Commit para persistir as alterações
            conn.commit()

            cursor.close()
            conn.close()

            # Retornar a resposta de sucesso
            return data_access_pb2.PostJobResponse(
                message="Job successfully inserted",
                status=200
            )

        except Exception as e:
            return data_access_pb2.PostJobResponse(
                message=f"Erro ao atualizar ou inserir o trabalho: {e}",
                status=500
            )

    def generate_unique_job_id(self, cursor):
        """Gera um ID único para o trabalho."""
        while True:
            # Gerar um ID aleatório
            new_id = random.randint(1, 999999)  # Exemplo: ID de 4 dígitos
            cursor.execute("SELECT * FROM jobs WHERE job_id = %s", (new_id,))
            if not cursor.fetchone():
                return new_id
        
    def GetRemoteJobs(self, request, context):
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

            query = """
            SELECT job_id, title, company, description, location, views, remote_allowed
            FROM jobs
            WHERE remote_allowed = TRUE
            """

            filters = []
            params = []

            if request.city and isinstance(request.city, str):
                filters.append("location ILIKE %s")
                params.append(f"%{request.city.strip()}%")

            if request.keyword and isinstance(request.keyword, str):
                filters.append("(title ILIKE %s OR description ILIKE %s)")
                params.append(f"%{request.keyword.strip()}%")
                params.append(f"%{request.keyword.strip()}%")

            if request.company and isinstance(request.company, str):
                filters.append("company ILIKE %s")
                params.append(f"%{request.company.strip()}%")

            if filters:
                query += " AND " + " AND ".join(filters)

            print("Executing Query:", query)
            print("Params:", params)

            cursor.execute(query, tuple(params))
            rows = cursor.fetchall()

            job_postings = []
            for row in rows:
                job_obj = JobForRemote(
                    id=row["job_id"],
                    title=row["title"] or "",
                    company=row["company"] or "",
                    description=row["description"] or "",
                    location=row["location"] or "",
                    remote_allowed=bool(row["remote_allowed"])
                )
                job_postings.append(job_obj)

            cursor.close()
            conn.close()

            return RemoteJobSearchResponse(jobs=job_postings)

        except Exception as e:
            print(f"Database query error: {str(e)}")
            context.set_details(f"Database query failed: {str(e)}")
            context.set_code(grpc.StatusCode.INTERNAL)
            return RemoteJobSearchResponse(jobs=[])

    def GetBestPayingCompanies(self, request, context):

        job_title = request.title

        if not job_title:
            context.set_details("Job title is required")
            context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
            return BestPayingCompaniesResponse()

        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

            query = """
            SELECT company, AVG(max_salary) as average_salary
            FROM jobs
            WHERE title = %s AND pay_period = 'YEARLY'
            GROUP BY company
            ORDER BY average_salary DESC
            """

            cursor.execute(query, (job_title,))
            rows = cursor.fetchall()

            companies = []
            for row in rows:
                company = BestCompany(
                    company_name=row["company"],
                    average_salary=row["average_salary"]
                )
                companies.append(company)

            cursor.close()
            conn.close()

            return BestPayingCompaniesResponse(companies=companies)

        except Exception as e:
            context.set_details(f"Database query failed: {str(e)}")
            context.set_code(grpc.StatusCode.INTERNAL)
            return BestPayingCompaniesResponse()
        
    def DeleteReview(self, request, context):
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            cursor = conn.cursor()

            cursor.execute("SELECT COUNT(*) FROM reviews WHERE id = %s", (request.review_id,))
            count = cursor.fetchone()[0]

            if count == 0:
                cursor.close()
                conn.close()
                context.set_code(grpc.StatusCode.NOT_FOUND)
                context.set_details("Review not found")
                return DeleteReviewResponse(success=False, message="Review not found")

            cursor.execute("DELETE FROM reviews WHERE id = %s", (request.review_id,))
            conn.commit()

            cursor.close()
            conn.close()

            return DeleteReviewResponse(success=True, message="Review deleted successfully")

        except Exception as e:
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(f"Error deleting Review: {str(e)}")
            return DeleteReviewResponse(success=False, message="Error deleting Review")

def serve():
    interceptors = [ExceptionToStatusInterceptor()]
    server = grpc.server(
        futures.ThreadPoolExecutor(max_workers=10), interceptors=interceptors
    )
    data_access_pb2_grpc.add_DataAccessServiceServicer_to_server(
        DataAccessService(), server
    )

    server.add_insecure_port("[::]:50051")
    server.start()
    server.wait_for_termination()

if __name__ == "__main__":
    serve()
