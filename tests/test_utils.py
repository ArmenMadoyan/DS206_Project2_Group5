"""Mocked unit tests for utils.py.

4 tests per original utility (Success / Failure / Edge / Boundary), all using
assert + unittest.mock. No live SQL Server or filesystem dependencies — every
external interaction is patched.
"""
import re
import sys
from pathlib import Path
from unittest.mock import MagicMock, mock_open, patch

import pytest

# Make the project root importable when tests are run from either repo root or tests/.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pyodbc

import utils


# --------------------------------------------------------------------------------------
# generate_uuid
# --------------------------------------------------------------------------------------

class TestGenerateUuid:
    def test_returns_str(self):
        result = utils.generate_uuid()
        assert isinstance(result, str)

    def test_is_unique_across_calls(self):
        a = utils.generate_uuid()
        b = utils.generate_uuid()
        assert a != b

    def test_matches_uuid4_regex(self):
        pattern = re.compile(
            r"^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
        )
        assert pattern.match(utils.generate_uuid()) is not None

    def test_takes_no_args(self):
        # Should not raise. Calling with extra args is a TypeError.
        utils.generate_uuid()
        with pytest.raises(TypeError):
            utils.generate_uuid("extra")  # type: ignore[arg-type]


# --------------------------------------------------------------------------------------
# read_sql_file
# --------------------------------------------------------------------------------------

class TestReadSqlFile:
    def test_returns_text(self, tmp_path):
        p = tmp_path / "q.sql"
        p.write_text("SELECT 1;", encoding="utf-8")
        assert utils.read_sql_file(p) == "SELECT 1;"

    def test_raises_filenotfound(self, tmp_path):
        missing = tmp_path / "nope.sql"
        with pytest.raises(FileNotFoundError):
            utils.read_sql_file(missing)

    def test_empty_file_ok(self, tmp_path):
        p = tmp_path / "empty.sql"
        p.write_text("", encoding="utf-8")
        assert utils.read_sql_file(p) == ""

    def test_preserves_utf8(self, tmp_path):
        p = tmp_path / "u.sql"
        p.write_text("-- ñ é 你好\nSELECT 1;", encoding="utf-8")
        assert "你好" in utils.read_sql_file(p)


# --------------------------------------------------------------------------------------
# execute_sql_script
# --------------------------------------------------------------------------------------

class TestExecuteSqlScript:
    def _conn(self):
        conn = MagicMock()
        cursor = MagicMock()
        conn.cursor.return_value = cursor
        return conn, cursor

    def test_calls_cursor_execute_with_text(self):
        conn, cursor = self._conn()
        utils.execute_sql_script(conn, "SELECT 1;")
        cursor.execute.assert_called_once_with("SELECT 1;")
        conn.commit.assert_called_once()

    def test_formats_params(self):
        conn, cursor = self._conn()
        utils.execute_sql_script(
            conn,
            "WHERE d BETWEEN '{StartDate}' AND '{EndDate}'",
            params={"StartDate": "2026-01-01", "EndDate": "2026-12-31"},
        )
        executed = cursor.execute.call_args[0][0]
        assert "2026-01-01" in executed and "2026-12-31" in executed

    def test_rolls_back_and_raises_on_pyodbc_error(self):
        conn, cursor = self._conn()
        cursor.execute.side_effect = pyodbc.Error("boom")
        with pytest.raises(pyodbc.Error):
            utils.execute_sql_script(conn, "SELECT 1;")
        conn.rollback.assert_called_once()
        conn.commit.assert_not_called()

    def test_accepts_none_params(self):
        conn, cursor = self._conn()
        utils.execute_sql_script(conn, "SELECT 1;", params=None)
        cursor.execute.assert_called_once_with("SELECT 1;")


# --------------------------------------------------------------------------------------
# get_database_connection
# --------------------------------------------------------------------------------------

class TestGetDatabaseConnection:
    def test_builds_dsn(self):
        with patch("utils.pyodbc.connect") as connect:
            utils.get_database_connection("srv", "db", "u", "p")
        dsn = connect.call_args[0][0]
        assert "SERVER=srv" in dsn
        assert "DATABASE=db" in dsn
        assert "UID=u" in dsn
        assert "PWD=p" in dsn

    def test_returns_conn(self):
        with patch("utils.pyodbc.connect") as connect:
            connect.return_value = MagicMock()
            conn = utils.get_database_connection("s", "d", "u", "p")
        assert conn is connect.return_value

    def test_raises_on_bad_creds(self):
        with patch("utils.pyodbc.connect", side_effect=pyodbc.Error("bad creds")):
            with pytest.raises(pyodbc.Error):
                utils.get_database_connection("s", "d", "u", "p")

    def test_respects_driver_arg(self):
        with patch("utils.pyodbc.connect") as connect:
            utils.get_database_connection("s", "d", "u", "p", driver="{Custom}")
        assert "DRIVER={Custom}" in connect.call_args[0][0]


# --------------------------------------------------------------------------------------
# run_sql_from_file
# --------------------------------------------------------------------------------------

class TestRunSqlFromFile:
    def test_reads_then_executes(self, tmp_path):
        p = tmp_path / "q.sql"
        p.write_text("SELECT 2;", encoding="utf-8")
        conn = MagicMock()
        cursor = MagicMock()
        conn.cursor.return_value = cursor
        utils.run_sql_from_file(conn, p)
        cursor.execute.assert_called_once_with("SELECT 2;")

    def test_forwards_params(self, tmp_path):
        p = tmp_path / "q.sql"
        p.write_text("WHERE d='{StartDate}'", encoding="utf-8")
        conn = MagicMock()
        cursor = MagicMock()
        conn.cursor.return_value = cursor
        utils.run_sql_from_file(conn, p, params={"StartDate": "2026-05-16"})
        executed = cursor.execute.call_args[0][0]
        assert "2026-05-16" in executed

    def test_propagates_filenotfound(self, tmp_path):
        conn = MagicMock()
        with pytest.raises(FileNotFoundError):
            utils.run_sql_from_file(conn, tmp_path / "missing.sql")

    def test_propagates_db_error(self, tmp_path):
        p = tmp_path / "q.sql"
        p.write_text("SELECT 1;", encoding="utf-8")
        conn = MagicMock()
        cursor = MagicMock()
        conn.cursor.return_value = cursor
        cursor.execute.side_effect = pyodbc.Error("nope")
        with pytest.raises(pyodbc.Error):
            utils.run_sql_from_file(conn, p)


# --------------------------------------------------------------------------------------
# close_connection
# --------------------------------------------------------------------------------------

class TestCloseConnection:
    def test_closes_conn(self):
        conn = MagicMock()
        utils.close_connection(conn)
        conn.close.assert_called_once()

    def test_handles_none(self):
        # Should not raise.
        utils.close_connection(None)

    def test_idempotent(self):
        conn = MagicMock()
        utils.close_connection(conn)
        utils.close_connection(conn)
        assert conn.close.call_count == 2

    def test_swallows_double_close(self):
        conn = MagicMock()
        conn.close.side_effect = [None, pyodbc.Error("already closed")]
        utils.close_connection(conn)
        utils.close_connection(conn)  # second call must not raise
        assert conn.close.call_count == 2


# --------------------------------------------------------------------------------------
# Bonus: tests for the 3 new utilities (parse_sql_config, get_db_connection_from_config,
# load_excel_to_staging). Not strictly required by the 24-test rule, but included
# because they exercise the highest-risk code paths.
# --------------------------------------------------------------------------------------

class TestParseSqlConfig:
    def _write(self, tmp_path, body):
        p = tmp_path / "cfg.cfg"
        p.write_text(body, encoding="utf-8")
        return p

    def test_returns_expected_dict(self, tmp_path):
        p = self._write(tmp_path, "[sql_server]\nserver=s\ndatabase=d\nusername=u\npassword=p\n")
        out = utils.parse_sql_config(p)
        assert out["server"] == "s" and out["database"] == "d"
        assert out["username"] == "u" and out["password"] == "p"

    def test_missing_section_raises(self, tmp_path):
        p = self._write(tmp_path, "[other]\nserver=s\n")
        with pytest.raises(KeyError):
            utils.parse_sql_config(p)

    def test_missing_key_raises(self, tmp_path):
        p = self._write(tmp_path, "[sql_server]\nserver=s\ndatabase=d\n")  # no user/pass
        with pytest.raises(KeyError):
            utils.parse_sql_config(p)

    def test_missing_file_raises(self, tmp_path):
        with pytest.raises(FileNotFoundError):
            utils.parse_sql_config(tmp_path / "nope.cfg")


class TestGetDbConnectionFromConfig:
    def test_composes_parse_and_connect(self, tmp_path):
        p = tmp_path / "c.cfg"
        p.write_text(
            "[sql_server]\nserver=s\ndatabase=d\nusername=u\npassword=p\n",
            encoding="utf-8",
        )
        with patch("utils.pyodbc.connect") as connect:
            connect.return_value = MagicMock()
            conn = utils.get_db_connection_from_config(p)
        assert conn is connect.return_value
        dsn = connect.call_args[0][0]
        assert "SERVER=s" in dsn and "DATABASE=d" in dsn

    def test_propagates_parse_error(self, tmp_path):
        with pytest.raises(FileNotFoundError):
            utils.get_db_connection_from_config(tmp_path / "missing.cfg")


class TestLoadExcelToStaging:
    def test_raises_on_missing_excel(self, tmp_path):
        conn = MagicMock()
        with pytest.raises(FileNotFoundError):
            utils.load_excel_to_staging(conn, tmp_path / "missing.xlsx", {"S": "t"})

    def test_inserts_per_sheet(self, tmp_path):
        import pandas as pd
        excel = tmp_path / "data.xlsx"
        with pd.ExcelWriter(excel, engine="openpyxl") as w:
            pd.DataFrame({"A": [1, 2], "B": ["x", "y"]}).to_excel(w, sheet_name="S1", index=False)
        conn = MagicMock()
        cursor = MagicMock()
        conn.cursor.return_value = cursor
        counts = utils.load_excel_to_staging(conn, excel, {"S1": "staging_t1"})
        assert counts["staging_t1"] == 2
        # DELETE was issued before INSERTs
        cursor.execute.assert_any_call("DELETE FROM staging_t1")
        cursor.executemany.assert_called_once()
        insert_sql = cursor.executemany.call_args[0][0]
        assert insert_sql.startswith("INSERT INTO staging_t1")
        conn.commit.assert_called_once()
