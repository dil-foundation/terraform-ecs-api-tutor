resource "aws_cloudfront_origin_access_identity" "s3_origin_access_identity" {
  comment = "Cloud front Access for Portal"
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket        = var.bucket_name
  force_destroy = true
  policy        = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
            "Sid": "CloudFrontRead",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_cloudfront_origin_access_identity.s3_origin_access_identity.iam_arn}"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.bucket_name}/*"
        }
  ]
}
EOF
  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  tags = var.tags
}

# Use the new aws_s3_bucket_versioning resource instead of deprecated versioning block
resource "aws_s3_bucket_versioning" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Suspended"
  }
}