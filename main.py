import argparse

from pipeline_dimensional_data.flow import DimensionalDataFlow


def parse_arguments():

    parser = argparse.ArgumentParser(
        description="Run dimensional data pipeline."
    )

    parser.add_argument(
        "--start_date",
        required=True,
        help="Start date in YYYY-MM-DD format"
    )

    parser.add_argument(
        "--end_date",
        required=True,
        help="End date in YYYY-MM-DD format"
    )

    return parser.parse_args()


if __name__ == "__main__":

    args = parse_arguments()
    flow = DimensionalDataFlow()
    result = flow.exec(
        start_date=args.start_date,
        end_date=args.end_date
    )

    print(result)