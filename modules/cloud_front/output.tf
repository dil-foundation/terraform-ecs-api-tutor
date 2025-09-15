

output "cloudfront_dns_record" {
  description = "The CloudFront DNS name"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_bucket_arn" {
  description = "ARN of the bucket for serving content."
  value       = aws_s3_bucket.web.arn
}

output "cloudfront_distribution" {
  description = "Cloudfront distribution (id, arn)"

  value = {
    id  = aws_cloudfront_distribution.cdn.id
    arn = aws_cloudfront_distribution.cdn.arn
    domain_name = aws_cloudfront_distribution.cdn.domain_name
  }
}
