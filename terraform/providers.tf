terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  # Partial backend config — bucket and region are passed via -backend-config
  # at init time so the account ID doesn't need to be hardcoded here.
  # CI bootstraps the state bucket automatically before terraform init.
  backend "s3" {
    key = "stock-mover/terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}
