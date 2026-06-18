import json
import logging
import os
from datetime import date, timedelta
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Injected by Terraform — resolves to the actual table name at deploy time
TABLE_NAME = os.environ["TABLE_NAME"]

# Reuse across warm invocations
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

# Returned on every response — "*" allows the S3-hosted frontend to call this API
HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
}


def decimal_default(obj):
    """json.dumps serializer — converts DynamoDB Decimal to float."""
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError(f"Type {type(obj)} not serializable")


def lambda_handler(event, context):
    today = date.today()

    # Generate the last 7 dates as partition key lookups (YYYY-MM-DD strings)
    dates = [(today - timedelta(days=i)).isoformat() for i in range(7)]

    # Use individual GetItem calls instead of Scan — cheaper and faster for known keys
    movers = []
    try:
        for date_str in dates:
            resp = table.get_item(Key={"date": date_str})
            item = resp.get("Item")
            if item:
                movers.append(item)

    except ClientError as e:
        logger.error("DynamoDB read failed: %s", e)
        return {
            "statusCode": 500,
            "headers": HEADERS,
            "body": json.dumps({"error": "Failed to retrieve data"}),
        }

    # Sort oldest → newest so frontend renders a chronological table without extra work
    movers.sort(key=lambda x: x["date"])

    logger.info("Returning %d movers", len(movers))
    return {
        "statusCode": 200,
        "headers": HEADERS,
        "body": json.dumps({"movers": movers}, default=decimal_default),
    }
