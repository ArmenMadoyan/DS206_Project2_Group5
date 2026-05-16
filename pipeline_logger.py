import logging
import logging.config
import os
from pathlib import Path


ROOT_LOGGER_NAME = "dimensional_pipeline"

LOG_DIR = Path(__file__).resolve().parent / "logs"
LOG_FILE = LOG_DIR / "logs_dimensional_data_pipeline.txt"

LOG_DIR.mkdir(parents=True, exist_ok=True)


class ExecutionIdFilter(logging.Filter):
    """Injects the run's execution_id onto every LogRecord so file output and
    GELF handler ship it as a structured field."""

    def __init__(self, execution_id):
        super().__init__()
        self.execution_id = execution_id

    def filter(self, record):
        record.execution_id = self.execution_id
        return True


def setup_logger(execution_id):
    """Configure the root pipeline logger. Idempotent: safe to call multiple times,
    but only the first call's execution_id is used (subsequent calls update the filter).

    Always attaches:
        - FileHandler   -> logs/logs_dimensional_data_pipeline.txt
        - StreamHandler -> stderr

    Conditionally attaches (when GRAYLOG_HOST env var is set):
        - graypy.GELFUDPHandler -> ${GRAYLOG_HOST}:${GRAYLOG_PORT:-12201}
    """

    config = {
        "version": 1,
        "disable_existing_loggers": False,
        "filters": {
            "execution_id": {
                "()": ExecutionIdFilter,
                "execution_id": execution_id,
            },
        },
        "formatters": {
            "pipeline": {
                "format": (
                    "%(asctime)s | "
                    "EXECUTION_ID=%(execution_id)s | "
                    "%(levelname)s | "
                    "%(name)s | "
                    "%(message)s"
                ),
            },
        },
        "handlers": {
            "file": {
                "class": "logging.FileHandler",
                "filename": str(LOG_FILE),
                "encoding": "utf-8",
                "formatter": "pipeline",
                "filters": ["execution_id"],
            },
            "stderr": {
                "class": "logging.StreamHandler",
                "formatter": "pipeline",
                "filters": ["execution_id"],
            },
        },
        "loggers": {
            ROOT_LOGGER_NAME: {
                "level": "INFO",
                "handlers": ["file", "stderr"],
                "propagate": False,
            },
        },
    }

    logging.config.dictConfig(config)
    root = logging.getLogger(ROOT_LOGGER_NAME)

    graylog_host = os.environ.get("GRAYLOG_HOST")
    if graylog_host:
        import graypy  # soft dep — only imported when the env var is set
        graylog_port = int(os.environ.get("GRAYLOG_PORT", "12201"))
        gelf = graypy.GELFUDPHandler(graylog_host, graylog_port)
        gelf.addFilter(ExecutionIdFilter(execution_id))
        root.addHandler(gelf)

    return root


def get_logger(name):
    """Return a logger that propagates to the dimensional_pipeline root."""

    if name == ROOT_LOGGER_NAME or name.startswith(ROOT_LOGGER_NAME + "."):
        return logging.getLogger(name)
    return logging.getLogger(f"{ROOT_LOGGER_NAME}.{name}")
