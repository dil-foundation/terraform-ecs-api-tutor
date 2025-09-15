output "s3_bucket_id" {
  value       = aws_s3_bucket.s3_bucket.id
  description = "The name of the bucket."
}

output "origin_access_identity" {
  value = aws_cloudfront_origin_access_identity.s3_origin_access_identity.cloudfront_access_identity_path
}