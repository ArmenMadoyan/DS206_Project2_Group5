from pathlib import Path
import configparser


REPO_ROOT = Path(__file__).resolve().parent.parent
CFG_PATH = REPO_ROOT / "sql_server_config.cfg"
QUERIES_DIR = Path(__file__).resolve().parent / "queries"
DATA_DIR = REPO_ROOT / "data"
EXCEL_PATH = DATA_DIR / "raw_data_source.xlsx"
LOG_DIR = REPO_ROOT / "logs"
LOG_FILE = LOG_DIR / "logs_dimensional_data_pipeline.txt"

INFRA_DIR = REPO_ROOT / "infrastructure_initiation"
INFRA_STAGING_DDL = INFRA_DIR / "staging_raw_table_creation.sql"
INFRA_DIM_DDL = INFRA_DIR / "dimensional_db_table_creation.sql"


_parser = configparser.ConfigParser()
_parser.read(CFG_PATH, encoding="utf-8")
_db = _parser["sql_server"]

SERVER = _db["server"]
DATABASE = _db["database"]
USERNAME = _db["username"]
PASSWORD = _db["password"]
DRIVER = _db.get("driver", "{ODBC Driver 18 for SQL Server}")


SHEET_TO_STAGING = {
    "Categories":   "staging_raw_categories",
    "Customers":    "staging_raw_customers",
    "Employees":    "staging_raw_employees",
    "Orders":       "staging_raw_orders",
    "OrderDetails": "staging_raw_order_details",
    "Products":     "staging_raw_products",
    "Region":       "staging_raw_region",
    "Shippers":     "staging_raw_shippers",
    "Suppliers":    "staging_raw_suppliers",
    "Territories":  "staging_raw_territories",
}


DIM_QUERY_FILES = [
    "update_dim_categories.sql",
    "update_dim_suppliers.sql",
    "update_dim_products.sql",
    "update_dim_region.sql",
    "update_dim_territories.sql",
    "update_dim_shippers.sql",
    "update_dim_employees.sql",
    "update_dim_customers.sql",
]
