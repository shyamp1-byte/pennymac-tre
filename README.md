# Stock Top Movers

Tracks which stock from a fixed watchlist moved the most each day (by % change), stores it, and shows the last 7 days on a simple dashboard.

Built on AWS using Terraform — no manual console clicks.

## How it works

```
EventBridge (daily cron @ 4:05 PM EST)
    → Lambda: pulls open/close prices from Massive API for each ticker
    → picks the biggest mover by absolute % change
    → writes to DynamoDB

API Gateway (GET /movers)
    → Lambda: reads last 7 days from DynamoDB
    → returns JSON to the frontend

S3: hosts the static frontend
```

**Watchlist:** AAPL, MSFT, GOOGL, AMZN, TSLA, NVDA

## Project layout

```
frontend/
  index.html          # the whole UI, no framework needed
lambdas/
  ingestion/
    handler.py        # runs on cron, fetches + stores the daily winner
    requirements.txt
  retrieval/
    handler.py        # serves GET /movers to the frontend
terraform/
  main.tf             # wires everything together
  modules/
    dynamodb/
    lambda/
    eventbridge/
    api_gateway/
```

## Deploying

You'll need Terraform >= 1.5, AWS CLI, Python 3, and a free [Massive](https://massive.com) API key.

**1. Set your AWS profile**
```bash
export AWS_PROFILE=your-profile
aws sts get-caller-identity
```

**2. Install Lambda dependencies**

`requests` isn't in the Lambda runtime, so install it into the source directory before Terraform zips it up:
```bash
pip install -r lambdas/ingestion/requirements.txt -t lambdas/ingestion/
```

**3. Deploy**
```bash
cd terraform
terraform init
terraform apply -var="stock_api_key=YOUR_MASSIVE_KEY"
```

This creates everything — DynamoDB, both Lambdas, EventBridge cron, API Gateway, and the S3 bucket.

**4. Wire the frontend to the API**

After apply, grab the API URL:
```bash
terraform output api_url
```

Open `frontend/index.html` and replace the placeholder:
```js
const API_URL = "REPLACE_WITH_TERRAFORM_OUTPUT_api_url";
```

**5. Upload the frontend**
```bash
terraform output frontend_url  # tells you the bucket name
aws s3 cp ../frontend/index.html s3://YOUR_BUCKET_NAME/index.html
```

Site is live at the `frontend_url` output.

## A few design decisions worth noting

**Separation of ingestion and retrieval** — two separate Lambdas with separate IAM roles. The ingestion role can only `PutItem`, the retrieval role can only `GetItem`. Neither can do more than it needs to.

**Retries on rate limits** — if Massive returns a 429, the ingestion Lambda backs off exponentially and retries up to 3 times per ticker. If one ticker fails entirely, it's skipped and the rest still run. Only aborts if every ticker fails.

**GetItem over Scan** — the retrieval Lambda makes 7 individual `GetItem` calls (one per date) instead of scanning the table. Cheaper and faster since we know the exact partition keys.

## Secrets

The Massive API key is passed as a Terraform variable marked `sensitive` — it never touches the codebase or git history. Pass it at deploy time:
```bash
terraform apply -var="stock_api_key=YOUR_KEY"
# or
export TF_VAR_stock_api_key=YOUR_KEY && terraform apply
```

## Teardown

```bash
cd terraform
terraform destroy -var="stock_api_key=placeholder"
```
