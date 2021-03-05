resource "aws_route53_record" "three-oh-one-IPv4" {
  for_each = var.sources
  zone_id  = each.value
  name     = each.key
  type     = "A"
  alias {
    name                   = aws_cloudfront_distribution.three-oh-one.domain_name
    zone_id                = aws_cloudfront_distribution.three-oh-one.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "three-oh-one-IPv6" {
  for_each = var.sources
  zone_id  = each.value
  name     = each.key
  type     = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.three-oh-one.domain_name
    zone_id                = aws_cloudfront_distribution.three-oh-one.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_s3_bucket" "three-oh-one" {
  bucket_prefix = "three-oh-one-"

  website {
    redirect_all_requests_to = var.target
  }
}

resource "aws_acm_certificate" "three-oh-one" {
  domain_name               = keys(var.sources)[0]
  subject_alternative_names = slice(keys(var.sources), 1, length(var.sources))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "three-oh-one" {
  for_each = {
    for dvo in aws_acm_certificate.three-oh-one.domain_validation_options : dvo.domain_name => {
      domain_name = dvo.domain_name
      name        = dvo.resource_record_name
      record      = dvo.resource_record_value
      type        = dvo.resource_record_type
    }
  }
  name    = each.value.name
  type    = each.value.type
  zone_id = lookup(var.sources, each.value.domain_name, "no zone found")
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "three-oh-one" {
  certificate_arn         = aws_acm_certificate.three-oh-one.arn
  validation_record_fqdns = [for record in aws_route53_record.three-oh-one : record.fqdn]
}

resource "aws_cloudfront_distribution" "three-oh-one" {
  origin {
    domain_name = aws_s3_bucket.three-oh-one.website_endpoint
    origin_id   = "s3bucket"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_100"

  aliases = keys(var.sources)

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    compress         = true
    target_origin_id = "s3bucket"
    default_ttl      = 31536000
    max_ttl          = 31536000
    min_ttl          = 0

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"

  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.three-oh-one.id
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  logging_config {
    include_cookies = false
    bucket          = var.logging_bucket
    prefix          = var.logging_prefix
  }
}
