import configparser
import uuid
from pathlib import Path

import pyodbc

from pipeline_logger import get_logger


pyodbc.pooling = False  # avoid pool reusing connections that still have pending results

logger = get_logger(__name__)


def generate_uuid():
    """Generate a unique UUID for tracking executions."""
    return str(uuid.uuid4())


def read_sql_file(file_path):
    """Read an SQL script from a .sql file. Accepts str or Path."""
    file_path = Path(file_path)
    if not file_path.exists():
        logger.error("sql.file.missing", extra={"path": str(file_path)})
        raise FileNotFoundError(f"The file '{file_path}' does not exist.")
    return file_path.read_text(encoding="utf-8")


def execute_sql_script(connection, sql_script, params=None):
    """Execute an SQL script using the provided database connection.

    If `params` is provided, the script is rendered via str.format(**params)
    before execution — placeholders like {StartDate} get substituted.
    """
    cursor = connection.cursor()
    try:
        if params:
            sql_script = sql_script.format(**params)
        logger.debug("sql.execute", extra={"params": params})
        cursor.execute(sql_script)
        connection.commit()
    except pyodbc.Error:
        logger.exception("sql.execute.failed")
        connection.rollback()
        raise
    finally:
        cursor.close()


def get_database_connection(
    server,
    database,
    username,
    password,
    driver="{ODBC Driver 18 for SQL Server}",
):
    """Establish a connection to a SQL Server database."""
    try:
        connection_string = (
            f"DRIVER={driver};"
            f"SERVER={server};"
            f"DATABASE={database};"
            f"UID={username};"
            f"PWD={password};"
            f"TrustServerCertificate=yes;"
        )
        logger.debug("db.connect", extra={"server": server, "database": database})
        connection = pyodbc.connect(connection_string)
        connection.autocommit = False
        return connection
    except pyodbc.Error:
        logger.exception("db.connect.failed", extra={"server": server, "database": database})
        raise


def run_sql_from_file(connection, file_path, params=None):
    """Read an SQL script from `file_path` and execute it on `connection`."""
    try:
        sql_script = read_sql_file(file_path)
        execute_sql_script(connection, sql_script, params)
        logger.info("sql.file.executed", extra={"path": str(file_path)})
    except Exception:
        logger.exception("sql.file.failed", extra={"path": str(file_path)})
        raise


def close_connection(connection):
    """Close a database connection if it is open. Safe to call with None."""
    if connection is None:
        return
    try:
        connection.close()
    except Exception:
        logger.exception("db.close.failed")


def parse_sql_config(cfg_path):
    """Parse a SQL Server connection config file.

    Returns a dict with keys: server, database, username, password, driver.
    Raises KeyError on missing required keys.
    """
    cfg_path = Path(cfg_path)
    parser = configparser.ConfigParser()
    read_files = parser.read(cfg_path, encoding="utf-8")
    if not read_files:
        logger.error("config.read.failed", extra={"path": str(cfg_path)})
        raise FileNotFoundError(f"Config file not found or unreadable: {cfg_path}")
    if "sql_server" not in parser:
        raise KeyError(f"Section [sql_server] missing in {cfg_path}")
    section = parser["sql_server"]
    required = ("server", "database", "username", "password")
    missing = [k for k in required if k not in section]
    if missing:
        raise KeyError(f"Missing keys in [sql_server]: {missing}")
    return {
        "server":   section["server"],
        "database": section["database"],
        "username": section["username"],
        "password": section["password"],
        "driver":   section.get("driver", "{ODBC Driver 18 for SQL Server}"),
    }


def get_db_connection_from_config(cfg_path, database=None):
    """Parse cfg + open a SQL Server connection in one call.

    Pass `database` to override the cfg's database (e.g. "master" for bootstrap).
    """
    cfg = parse_sql_config(cfg_path)
    return get_database_connection(
        server=cfg["server"],
        database=database or cfg["database"],
        username=cfg["username"],
        password=cfg["password"],
        driver=cfg["driver"],
    )


def load_excel_to_staging(connection, excel_path, sheet_to_table):
    """Load each Excel sheet into its target staging-raw table.

    For every (sheet_name, table_name) pair in `sheet_to_table`:
      1. DELETE FROM <table_name>
      2. INSERT every row from <sheet_name> via fast_executemany.

    Returns a dict of {table_name: row_count}.
    """
    import pandas as pd  # local import keeps utils importable without pandas in tests

    excel_path = Path(excel_path)
    if not excel_path.exists():
        logger.error("excel.missing", extra={"path": str(excel_path)})
        raise FileNotFoundError(f"Excel file not found: {excel_path}")

    cursor = connection.cursor()
    cursor.fast_executemany = True
    row_counts = {}
    try:
        for sheet_name, table_name in sheet_to_table.items():
            df = pd.read_excel(excel_path, sheet_name=sheet_name)
            cursor.execute(f"DELETE FROM {table_name}")
            if df.empty:
                row_counts[table_name] = 0
                logger.info("staging.empty", extra={"sheet": sheet_name, "table": table_name})
                continue
            columns = list(df.columns)
            placeholders = ", ".join(["?"] * len(columns))
            col_list = ", ".join(f"[{c}]" for c in columns)
            insert_sql = f"INSERT INTO {table_name} ({col_list}) VALUES ({placeholders})"
            def _norm(v):
                if v is None:
                    return None
                if hasattr(v, "to_pydatetime"):
                    return None if pd.isna(v) else v.to_pydatetime()
                if isinstance(v, float) and pd.isna(v):
                    return None
                if isinstance(v, str) and v == "":
                    return None
                return v
            rows = [tuple(_norm(v) for v in row) for row in df.itertuples(index=False, name=None)]
            cursor.executemany(insert_sql, rows)
            row_counts[table_name] = len(df)
            logger.info(
                "staging.loaded",
                extra={"sheet": sheet_name, "table": table_name, "rows": len(df)},
            )
        connection.commit()
        return row_counts
    except Exception:
        connection.rollback()
        logger.exception("staging.load.failed")
        raise
    finally:
        cursor.close()
