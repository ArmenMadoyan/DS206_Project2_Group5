# DS206 Project 2 — Group 5

Dimensional data warehouse pipeline (staging → dimensions → fact → fact-error) for the Northwind dataset, targeting Microsoft SQL Server.

## Prerequisites

### 1. SQL Server
A reachable SQL Server instance. **You don't need to pre-create `ORDER_DDS` or any tables** — the pipeline bootstraps the database and schema on first run (see [How it runs](#how-it-runs)).

**macOS (Apple Silicon)** — SQL Server has no native macOS build. Use Azure SQL Edge in Docker. Easiest path is the provided compose file:
```bash
docker compose up -d
```
…or a one-shot container:
```bash
docker run -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD='StrongPassword123!' \
  -p 1433:1433 --name mssql -d mcr.microsoft.com/azure-sql-edge:latest
```
If Docker isn't installed: `brew install --cask docker`, open Docker Desktop once, then run the above.

> **Important:** use `127.0.0.1` (not `localhost`) in `sql_server_config.cfg`. macOS resolves `localhost` to IPv6 first, but Docker's port mapping is IPv4-only — the IPv6 attempt will hang until login timeout.

**Linux / Windows** — install SQL Server normally. Match the credentials in `sql_server_config.cfg` (see [Configuration](#configuration)).

### 2. Microsoft ODBC Driver 18 for SQL Server
**Required** — `pyodbc` connects through this driver. Without it you'll see:
```
pyodbc.Error: ... Can't open lib 'ODBC Driver 18 for SQL Server' : file not found
```

**macOS (Homebrew):**
```bash
brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
HOMEBREW_NO_ENV_FILTERING=1 ACCEPT_EULA=Y brew install msodbcsql18 mssql-tools18
```

**Linux (Debian/Ubuntu):** see [Microsoft's docs](https://learn.microsoft.com/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server).

**Windows:** the driver ships with SSMS / can be downloaded from Microsoft.

Verify with:
```bash
odbcinst -q -d   # should list "ODBC Driver 18 for SQL Server"
```

### 3. Python 3.10+
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Configuration

The pipeline reads DB credentials from `sql_server_config.cfg` at the repo root (gitignored).

```bash
cp sql_server_config.cfg.example sql_server_config.cfg
# then edit sql_server_config.cfg and set your password
```

## How it runs

```bash
python main.py --start_date=1996-01-01 --end_date=1998-12-31
```

`DimensionalDataFlow.exec()` runs five atomic tasks in order, each gated on the previous one's `{"success": True}`:

1. **bootstrap_schema** — creates `ORDER_DDS` (connects to `master`) if absent; applies `staging_raw_table_creation.sql` and `dimensional_db_table_creation.sql` only if the marker tables don't exist. Idempotent — safe to re-run.
2. **load_staging_tables** — reads each sheet of `data/raw_data_source.xlsx` via pandas and bulk-inserts into the matching `staging_raw_*` table (NaN / NaT / empty strings → `NULL`; pandas `Timestamp` → Python `datetime`).
3. **run_dimension_ingestion** — executes every `update_dim_*.sql` against ORDER_DDS in FK-friendly order (categories, suppliers, products, region, territories, shippers, employees, customers).
4. **run_fact_ingestion** — MERGEs into `FactOrders` (Group 5's FactOrders is SNAPSHOT).
5. **run_fact_error_ingestion** — appends rows with missing/invalid natural keys to `FactOrdersError` for the supplied `[start_date, end_date]` window.

Logs are appended to `logs/logs_dimensional_data_pipeline.txt`, each line tagged with the run's `execution_id` (uuid).

## Tests

```bash
pytest tests/test_utils.py
```

**32 tests**, runtime ~0.4s. The filesystem and `pyodbc` are mocked — no live SQL Server connection required. Coverage: 4 tests per utility function in `utils.py`.

## Project layout

```
infrastructure_initiation/   DDL: database, staging-raw, dimensional/fact tables
pipeline_dimensional_data/   flow.py, tasks.py, config.py, queries/ (parametrized SQL)
logs/                        runtime log file
dashboard/                   Power BI .pbix (bonus)
data/                        raw_data_source.xlsx
tests/                       pytest-based unit tests for utils.py
main.py                      CLI entry: parse args → DimensionalDataFlow().exec()
utils.py                     flow-agnostic helpers (config parsing, SQL exec, Excel→staging)
pipeline_logger.py           logger setup with execution_id formatting
```