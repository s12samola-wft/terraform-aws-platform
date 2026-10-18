terraform {
  required_version = ">= 1.16.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1"

  default_tags {
    tags = {
      Project   = "terraform-aws-platform"
      ManagedBy = "Terraform"
      Purpose   = "terraform-state"
    }
  }
}

# The vault. Bucket names are GLOBAL across all of AWS, so it must be unique.
resource "aws_s3_bucket" "tf_state" {
  bucket = "s12samola-terraform-aws-platform-tfstate"

  # Refuse any plan that would delete this bucket
  lifecycle {
    prevent_destroy = true
  }
}

# Photocopies of every old version of the register
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lock the vault: encrypt everything stored in it
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# No windows: block every form of public access
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}
# Rule on the vault door: refuse any request that isn't using HTTPS
data "aws_iam_policy_document" "tf_state_tls_only" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.tf_state.arn,        # the bucket itself
      "${aws_s3_bucket.tf_state.arn}/*", # every file inside it
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"] # "if the request is NOT encrypted..."
    }
  }
}

resource "aws_s3_bucket_policy" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  policy = data.aws_iam_policy_document.tf_state_tls_only.json
}