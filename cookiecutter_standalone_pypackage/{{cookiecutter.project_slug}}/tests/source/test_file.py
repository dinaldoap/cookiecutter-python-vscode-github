from datetime import date, datetime

import pandas as pd
from pandas.testing import assert_frame_equal

from capgain.source.file import *


def test_StandardTarget():
    output = StandardPortfolio("tests/data/portfolio.xlsx").read()
    expected = pd.DataFrame(
        {
            "Name": [
                "iShares Core S&P Total US Stock Market ETF",
                "iShares Core MSCI EAFE ETF",
            ],
            "Ticker": ["BITO39", "BIEF39"],
            "Target": [0.2, 0.8],
            "Group": ["A", None],
        }
    )
    assert_frame_equal(expected, output[["Name", "Ticker", "Target", "Group"]])


def test_DirectoryChange():
    output = DirectoryChange("tests/data/change", date=None).read()
    _assert_change(output)


def _assert_change(output):
    expected = pd.DataFrame(
        {
            "Date": [
                datetime(2021, 2, 1),
                datetime(2021, 2, 2),
                datetime(2021, 1, 1),
                datetime(2021, 1, 2),
            ],
            "Ticker": ["BIEF39", "BIEF39", "BITO39", "BITO39"],
            "Change": [2, -2, 1, -1],
            "Price": [2.22, 2.22, 1.11, 1.11],
        }
    ).set_index("Date")
    assert_frame_equal(expected, output)
