import json
import logging
import os
import time
from datetime import date
from decimal import Decimal

import boto3
import requests
from botocore.exceptions import ClientError

# Lambda reuses this logger across warm invocations
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Stocks to track — absolute % change winner stored each day
WATCHLIST = ["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "NVDA"]

# Injected by Terraform at deploy time — never hardcoded
TABLE_NAME = os.environ["TABLE_NAME"]
API_KEY = os.environ["STOCK_API_KEY"]
# Polygon.io free tier — override via env var to swap providers without code changes
API_BASE_URL = os.environ.get("STOCK_API_BASE_URL", "https://api.polygon.io")

# Reuse the DynamoDB resource across warm invocations (avoids reconnect overhead)
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


def fetch_daily_bar(ticker: str, date_str: str, retries: int = 3) -> dict:
    """Fetch open/close bar for a single ticker on a given date, with retry on rate limit."""
    url = f"{API_BASE_URL}/v1/open-close/{ticker}/{date_str}"
    params = {"adjusted": "true", "apiKey": API_KEY}

    for attempt in range(retries):
        try:
            resp = requests.get(url, params=params, timeout=10)

            if resp.status_code == 429:
                # Exponential backoff: 1s, 2s, 4s — avoids hammering a rate-limited API
                wait = 2 ** attempt
                logger.warning("Rate limited on %s, retrying in %ds", ticker, wait)
                time.sleep(wait)
                continue

            resp.raise_for_status()
            return resp.json()

        except requests.RequestException as e:
            if attempt == retries - 1:
                raise  # Out of retries — let caller decide what to do
            logger.warning("Request failed for %s (attempt %d): %s", ticker, attempt + 1, e)
            time.sleep(2 ** attempt)

    raise RuntimeError(f"Failed to fetch {ticker} after {retries} retries")


def lambda_handler(event, context):
    today = date.today().isoformat()  # YYYY-MM-DD — used as DynamoDB partition key
    logger.info("Running ingestion for %s", today)

    # Collect % change for every ticker; skip failures so one bad ticker doesn't abort the run
    results = []
    for ticker in WATCHLIST:
        try:
            data = fetch_daily_bar(ticker, today)
            open_price = data["open"]
            close_price = data["close"]

            # Standard daily % change formula — negative = loss, positive = gain
            pct_change = ((close_price - open_price) / open_price) * 100
            results.append({
                "ticker": ticker,
                "percent_change": pct_change,
                "closing_price": close_price,
            })
            logger.info("%s: %.2f%%", ticker, pct_change)

        except Exception as e:
            logger.error("Skipping %s: %s", ticker, e)

    # If every ticker failed, nothing useful to store
    if not results:
        logger.error("No stock data retrieved for any ticker — aborting write")
        return {"statusCode": 500, "body": json.dumps({"error": "No stock data available"})}

    # Pick the stock with the largest move, regardless of direction (abs value)
    winner = max(results, key=lambda x: abs(x["percent_change"]))

    try:
        # DynamoDB requires Decimal (not float) for numeric types
        table.put_item(Item={
            "date": today,
            "ticker": winner["ticker"],
            "percent_change": Decimal(str(round(winner["percent_change"], 4))),
            "closing_price": Decimal(str(winner["closing_price"])),
        })
        logger.info("Stored winner: %s (%.2f%%)", winner["ticker"], winner["percent_change"])

    except ClientError as e:
        logger.error("DynamoDB write failed: %s", e)
        raise  # Re-raise so Lambda marks the invocation as failed (triggers CloudWatch alert)

    return {"statusCode": 200, "body": json.dumps({"winner": winner["ticker"]})}
