data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.web.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

data "aws_caller_identity" "current" {
}

locals {
  bucket_name_default = "${data.aws_caller_identity.current.account_id}-${var.environment}-${var.name}"
  bucket_name         = var.bucket_name == "" ? local.bucket_name_default : var.bucket_name
}

resource "aws_s3_bucket_policy" "web" {
  bucket = aws_s3_bucket.web.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_s3_bucket" "web" {
  bucket        = local.bucket_name
  force_destroy = var.bucket_force_destroy

  tags = merge(
    {
      "Name" = format("%s", "Bucket for CloudFront ${var.environment}")
    },
    {
      "Environment" = format("%s", var.environment)
    },
    var.tags,
  )
}

# Use the new aws_s3_bucket_acl resource instead of deprecated acl block
resource "aws_s3_bucket_acl" "web" {
  bucket = aws_s3_bucket.web.id
  acl    = var.bucket_acl
}

# Use the new aws_s3_bucket_versioning resource instead of deprecated versioning block
resource "aws_s3_bucket_versioning" "web" {
  bucket = aws_s3_bucket.web.id
  versioning_configuration {
    status = var.bucket_versioning ? "Enabled" : "Suspended"
  }
}

# Use the new aws_s3_bucket_lifecycle_configuration resource instead of deprecated lifecycle_rule block
resource "aws_s3_bucket_lifecycle_configuration" "web" {
  count  = var.bucket_versioning ? 1 : 0
  bucket = aws_s3_bucket.web.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}