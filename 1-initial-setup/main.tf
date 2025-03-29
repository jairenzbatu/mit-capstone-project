terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}
provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_s3_bucket" "snipe_seed" {
  bucket = "jairenz-snipe-seed"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.snipe_seed.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.snipe_seed.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.snipe_seed.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "database_dump_folder" {
  bucket = aws_s3_bucket.snipe_seed.id
  key    = "database-dump/"
}

resource "aws_s3_object" "application_data_folder" {
  bucket = aws_s3_bucket.snipe_seed.id
  key    = "application-data/"
}
