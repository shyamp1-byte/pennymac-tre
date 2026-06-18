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
.github/
  workflows/
    deploy.yml        # CI/CD — auto-deploys on every push to main
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

**3. Create the Terraform state bucket** (one-time)
```bash
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
aws s3 mb s3://stock-mover-tfstate-${ACCOUNT} --region us-east-1
aws s3api put-bucket-versioning \
  --bucket stock-mover-tfstate-${ACCOUNT} \
  --versioning-configuration Status=Enabled
```

**4. Deploy**
```bash
cd terraform
terraform init \
  -backend-config="bucket=stock-mover-tfstate-${ACCOUNT}" \
  -backend-config="region=us-east-1"
terraform apply -var="stock_api_key=YOUR_MASSIVE_KEY"
```

This creates everything — DynamoDB, both Lambdas, EventBridge cron, API Gateway, and the S3 bucket.

**5. Upload the frontend**
```bash
BUCKET=$(terraform output -raw bucket_name)
aws s3 cp ../frontend/index.html s3://${BUCKET}/index.html
```

Site is live at the `frontend_url` output.

## CI/CD

Every push to `main` auto-deploys via GitHub Actions. Add three repository secrets under **Settings → Secrets and variables → Actions**:

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `STOCK_API_KEY` | Massive API key |

The workflow installs dependencies, bootstraps remote state, runs `terraform apply`, and uploads the frontend — no manual steps needed.

## A few design decisions worth noting

**Separation of ingestion and retrieval** — two separate Lambdas with separate IAM roles. The ingestion role can only `PutItem`, the retrieval role can only `GetItem`. Neither can do more than it needs to.

**Retries on rate limits** — if Massive returns a 429, the ingestion Lambda backs off exponentially and retries up to 3 times per ticker. If one ticker fails entirely, it's skipped and the rest still run. Only aborts if every ticker fails.

**GetItem over Scan** — the retrieval Lambda makes 7 individual `GetItem` calls (one per date) instead of scanning the table. Cheaper and faster since we know the exact partition keys.

**Remote Terraform state** — state is stored in S3 so CI/CD runs don't lose track of existing infrastructure between deploys.

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
