locals {
  cdn_url = "assets.kiba.dev"
}

data "aws_acm_certificate" "kibadev" {
  domain = "kiba.dev"
  provider = aws.virginia
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"
  price_class = "PriceClass_100"
  aliases = ["assets-cdn.kiba.dev"]
  # aliases = ["assets-cdn.kiba.dev", "assets.evrpg.com"]

  origin {
    origin_id = local.cdn_url
    domain_name = local.cdn_url

    custom_origin_config {
      http_port = "80"
      https_port = "443"
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  ordered_cache_behavior {
    target_origin_id = local.cdn_url
    path_pattern = "/.well-known/*"
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    viewer_protocol_policy = "allow-all"
    default_ttl = 86400
    min_ttl = 0
    max_ttl = 31536000

    forwarded_values {
      headers = ["Host"]
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  default_cache_behavior {
    target_origin_id = local.cdn_url
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"
    compress = true
    default_ttl = 86400
    min_ttl = 0
    max_ttl = 31536000

    forwarded_values {
      headers = ["Host"]
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations = []
    }
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.kibadev.arn
    ssl_support_method = "sni-only"
  }
}
