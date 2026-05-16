from utils import (
    close_connection,
    get_db_connection_from_config,
    load_excel_to_staging,
    parse_sql_config,
    read_sql_file,
    run_sql_from_file,
)
from pipeline_dimensional_data.config import (
    CFG_PATH,
    DIM_QUERY_FILES,
    EXCEL_PATH,
    INFRA_DIM_DDL,
    INFRA_STAGING_DDL,
    QUERIES_DIR,
    SHEET_TO_STAGING,
)
from pipeline_logger import get_logger


logger = get_logger(__name__)


def _skip_if_previous_failed(previous_task):
    if previous_task and not previous_task.get("success", True):
        return {"success": False, "skipped": True}
    return None


def bootstrap_schema(previous_task=None):
    """Ensure ORDER_DDS database, staging-raw tables, and dim/fact tables exist.

    Idempotent: skips DDL when the marker table is already present.
    """
    skip = _skip_if_previous_failed(previous_task)
    if skip:
        return skip
    master_conn = None
    conn = None
    try:
        logger.info("task.started", extra={"task": "bootstrap"})
        cfg = parse_sql_config(CFG_PATH)
        target_db = cfg["database"]

        master_conn = get_db_connection_from_config(CFG_PATH, database="master")
        master_conn.autocommit = True
        master_conn.cursor().execute(
            f"IF DB_ID('{target_db}') IS NULL EXEC('CREATE DATABASE [{target_db}]')"
        )

        conn = get_db_connection_from_config(CFG_PATH)
        conn.autocommit = True
        cur = conn.cursor()
        if cur.execute("SELECT OBJECT_ID('dbo.Dim_SOR', 'U')").fetchval() is None:
            cur.execute(read_sql_file(INFRA_DIM_DDL))
            logger.info("bootstrap.dim_ddl.applied")
        if cur.execute("SELECT OBJECT_ID('dbo.staging_raw_categories', 'U')").fetchval() is None:
            cur.execute(read_sql_file(INFRA_STAGING_DDL))
            logger.info("bootstrap.staging_ddl.applied")

        logger.info("task.succeeded", extra={"task": "bootstrap"})
        return {"success": True}
    except Exception as e:
        logger.exception("task.failed", extra={"task": "bootstrap"})
        return {"success": False, "error": str(e)}
    finally:
        close_connection(master_conn)
        close_connection(conn)


def load_staging_tables(previous_task=None):
    skip = _skip_if_previous_failed(previous_task)
    if skip:
        return skip
    conn = None
    try:
        logger.info("task.started", extra={"task": "load_staging"})
        conn = get_db_connection_from_config(CFG_PATH)
        load_excel_to_staging(conn, EXCEL_PATH, SHEET_TO_STAGING)
        logger.info("task.succeeded", extra={"task": "load_staging"})
        return {"success": True}
    except Exception as e:
        logger.exception("task.failed", extra={"task": "load_staging"})
        return {"success": False, "error": str(e)}
    finally:
        close_connection(conn)


def run_dimension_ingestion(start_date, end_date, previous_task):
    skip = _skip_if_previous_failed(previous_task)
    if skip:
        return skip
    conn = None
    try:
        logger.info(
            "task.started",
            extra={"task": "dims", "start_date": start_date, "end_date": end_date},
        )
        conn = get_db_connection_from_config(CFG_PATH)
        for fname in DIM_QUERY_FILES:
            run_sql_from_file(conn, QUERIES_DIR / fname)
            logger.info("dim.loaded", extra={"file": fname})
        logger.info("task.succeeded", extra={"task": "dims"})
        return {"success": True}
    except Exception as e:
        logger.exception("task.failed", extra={"task": "dims"})
        return {"success": False, "error": str(e)}
    finally:
        close_connection(conn)


def run_fact_ingestion(start_date, end_date, previous_task):
    skip = _skip_if_previous_failed(previous_task)
    if skip:
        return skip
    conn = None
    try:
        logger.info(
            "task.started",
            extra={"task": "fact", "start_date": start_date, "end_date": end_date},
        )
        conn = get_db_connection_from_config(CFG_PATH)
        run_sql_from_file(
            conn,
            QUERIES_DIR / "update_fact.sql",
            params={"StartDate": start_date, "EndDate": end_date},
        )
        logger.info("task.succeeded", extra={"task": "fact"})
        return {"success": True}
    except Exception as e:
        logger.exception("task.failed", extra={"task": "fact"})
        return {"success": False, "error": str(e)}
    finally:
        close_connection(conn)


def run_fact_error_ingestion(start_date, end_date, previous_task):
    skip = _skip_if_previous_failed(previous_task)
    if skip:
        return skip
    conn = None
    try:
        logger.info(
            "task.started",
            extra={"task": "fact_error", "start_date": start_date, "end_date": end_date},
        )
        conn = get_db_connection_from_config(CFG_PATH)
        run_sql_from_file(
            conn,
            QUERIES_DIR / "update_fact_error.sql",
            params={"StartDate": start_date, "EndDate": end_date},
        )
        logger.info("task.succeeded", extra={"task": "fact_error"})
        return {"success": True}
    except Exception as e:
        logger.exception("task.failed", extra={"task": "fact_error"})
        return {"success": False, "error": str(e)}
    finally:
        close_connection(conn)
