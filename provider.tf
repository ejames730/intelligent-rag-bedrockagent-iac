// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.3"
    }
  }
}

# Access keys and tokens are stored in Bitwarden for profile james.emling
provider "aws" {
  region  = "us-west-1"
  profile = "james.emling"

  default_tags {
    tags = {
      Environment   = var.env_name
      Application   = "bedrock-agent"
      deploy-date   = "09142025"
    }
  }
}
