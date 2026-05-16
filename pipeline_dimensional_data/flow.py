from utils import generate_uuid
from pipeline_dimensional_data.tasks import (
    bootstrap_schema,
    load_staging_tables,
    run_dimension_ingestion,
    run_fact_error_ingestion,
    run_fact_ingestion,
)
from pipeline_logger import setup_logger


class DimensionalDataFlow:

    def __init__(self):
        self.execution_id = generate_uuid()
        self.logger = setup_logger(self.execution_id)

    def exec(self, start_date, end_date):
        self.logger.info("pipeline.started", extra={"start_date": start_date, "end_date": end_date})

        bootstrap_result = bootstrap_schema()
        if not bootstrap_result["success"]:
            self.logger.error("pipeline.aborted", extra={"stage": "bootstrap"})
            return {"success": False, "stage": "bootstrap", "execution_id": self.execution_id}

        staging_result = load_staging_tables(previous_task=bootstrap_result)
        if not staging_result["success"]:
            self.logger.error("pipeline.aborted", extra={"stage": "staging"})
            return {"success": False, "stage": "staging", "execution_id": self.execution_id}

        dimension_result = run_dimension_ingestion(
            start_date=start_date,
            end_date=end_date,
            previous_task=staging_result,
        )
        if not dimension_result["success"]:
            self.logger.error("pipeline.aborted", extra={"stage": "dimensions"})
            return {"success": False, "stage": "dimensions", "execution_id": self.execution_id}

        fact_result = run_fact_ingestion(
            start_date=start_date,
            end_date=end_date,
            previous_task=dimension_result,
        )
        if not fact_result["success"]:
            self.logger.error("pipeline.aborted", extra={"stage": "fact"})
            return {"success": False, "stage": "fact", "execution_id": self.execution_id}

        fact_error_result = run_fact_error_ingestion(
            start_date=start_date,
            end_date=end_date,
            previous_task=fact_result,
        )
        if not fact_error_result["success"]:
            self.logger.error("pipeline.aborted", extra={"stage": "fact_error"})
            return {"success": False, "stage": "fact_error", "execution_id": self.execution_id}

        self.logger.info("pipeline.succeeded", extra={"execution_id": self.execution_id})
        return {"success": True, "execution_id": self.execution_id}
