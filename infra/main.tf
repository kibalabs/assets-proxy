terraform {
  required_version = "~> 1.3.7"

  # aws s3 --profile kiba mb s3://kiba-infra-assets-proxy
  backend "s3" {
    key = "tf-state.json"
    region = "eu-west-1"
    bucket = "kiba-infra-assets-proxy"
    profile = "kiba"
    encrypt = true
  }

  required_providers {
    aws = {
      version = "5.14.0"
    }
  }
}

provider "aws" {
  profile = "kiba"
  region = "eu-west-1"
}

provider "aws" {
  alias = "virginia"
  profile = "kiba"
  region = "us-east-1"
}

locals {
  project = "assets-proxy"
}
