#https://gist.github.com/gnouts/40a20c986b202633da334a7246e47337

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "${var.environment}-cloudfront-access-identity"
}

data "aws_lb" "aws_alb" {
  count = var.enable_backend ? 1 : 0
  arn   = var.load_balancer_arn
}

data "aws_s3_bucket" "front" {
  bucket = var.bucket_id
}

resource "aws_cloudfront_distribution" "cdn" {
  # front
  origin {
    origin_id   = data.aws_s3_bucket.front.id
    domain_name = data.aws_s3_bucket.front.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = var.origin_access_identity
    }
  }
  
  # back (optional)
  dynamic "origin" {
    for_each = var.enable_backend ? [1] : []
    content {
      origin_id   = data.aws_lb.aws_alb[0].name
      domain_name = data.aws_lb.aws_alb[0].dns_name
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1", "SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }
  }

  # API Gateway origin (optional)
  dynamic "origin" {
    for_each = var.enable_api_gateway && var.api_gateway_invoke_url != "" ? [1] : []
    content {
      origin_id   = "api-gateway"
      domain_name = var.api_gateway_domain_name
      origin_path = "/${split("/", var.api_gateway_invoke_url)[length(split("/", var.api_gateway_invoke_url)) - 1]}"
      custom_origin_config {
        http_port              = 443
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  restrictions {
    geo_restriction {
      locations        = var.restrictions_geo_restriction_location
      restriction_type = var.restrictions_geo_restriction_restriction_type
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.default_root_object

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = data.aws_s3_bucket.front.id

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"

    min_ttl     = var.min_ttl
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl
  }

  # API Routes to API Gateway (higher precedence)
  dynamic "ordered_cache_behavior" {
    for_each = var.enable_api_gateway && var.api_gateway_invoke_url != "" ? [1] : []
    content {
      path_pattern     = "/api/*"
      allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "api-gateway"

      forwarded_values {
        query_string = true
        headers      = ["Authorization", "Content-Type", "Accept"]
        cookies {
          forward = "none"
        }
      }

      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
      compress               = false
      viewer_protocol_policy = "redirect-to-https"
    }
  }

  # All API routes now go through API Gateway (no ALB fallback)

  # All API routes now go through API Gateway (CloudFront → API Gateway → Lambda → ECS → RDS)
  # Only admin panel and health check routes go directly to ALB for management purposes

  # Health Check Route to Backend (for direct health monitoring)
  dynamic "ordered_cache_behavior" {
    for_each = var.enable_backend ? [1] : []
    content {
      path_pattern     = "/health"
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = data.aws_lb.aws_alb[0].name
      forwarded_values {
        query_string = true
        headers      = ["Accept", "Accept-Charset", "Accept-Datetime","Accept-Encoding","Accept-Language","Authorization","Host","Origin","Referer"]
        cookies {
          forward = "all"
        }
      }
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
      compress               = false
      viewer_protocol_policy = "redirect-to-https"
    }
  }

  price_class = var.price_class
  tags = merge(
    {
      "Name" = format(
        "%s",
        "CloudFront Distribution ${var.environment}-${var.name}",
      )
    },
    {
      "Environment" = format("%s", var.environment)
    },
    var.tags,
  )

  viewer_certificate {
    cloudfront_default_certificate = var.enable_route53_record ? false : true
    acm_certificate_arn            = var.enable_route53_record ? var.ssl_certificate_arn : ""
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = var.ssl_minimum_protocol_version
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_response
    content {
      error_code            = custom_error_response.value["error_code"]
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", 30)
      response_code         = lookup(custom_error_response.value, "response_code", 200)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", "/index.html")
    }
  }
}