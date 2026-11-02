locals {
  cdn_domain_names = ["assets-cdn.kiba.dev", "assets.evrpg.com"]
  storage_origin_id = "storage"
  google_fonts_origin_id = "google-fonts"
  google_fonts_files_origin_id = "google-fonts-files"
  calendly_origin_id = "calendly"
}

data "aws_acm_certificate" "kibadev" {
  domain = "kiba.dev"
  most_recent = true
  provider = aws.virginia
}

resource "aws_cloudfront_origin_access_control" "storage" {
  name = "${local.project}-storage"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

# NOTE(krishan711): /gfonts/css2?... is served by fonts.googleapis.com/css2?... and /gfonts-files/... by fonts.gstatic.com/...
resource "aws_cloudfront_function" "strip_gfonts_prefix" {
  name = "${local.project}-strip-gfonts-prefix"
  runtime = "cloudfront-js-2.0"
  publish = true
  code = <<-EOT
    function handler(event) {
      var request = event.request;
      var prefix = request.uri.indexOf('/gfonts-files') === 0 ? '/gfonts-files' : '/gfonts';
      request.uri = request.uri.substring(prefix.length) || '/';
      return request;
    }
  EOT
}

resource "aws_cloudfront_function" "calendly_widget" {
  name = "${local.project}-calendly-widget"
  runtime = "cloudfront-js-2.0"
  publish = true
  code = <<-EOT
    function handler(event) {
      var request = event.request;
      request.uri = '/assets/external/widget.js';
      return request;
    }
  EOT
}

resource "aws_cloudfront_cache_policy" "assets" {
  name = "${local.project}-assets"
  min_ttl = 0
  default_ttl = 86400
  max_ttl = 31536000

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip = true
    enable_accept_encoding_brotli = true
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "cors" {
  name = "${local.project}-cors"

  cors_config {
    access_control_allow_credentials = false
    access_control_max_age_sec = 3600
    origin_override = true

    access_control_allow_headers {
      items = ["Range"]
    }
    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS"]
    }
    access_control_allow_origins {
      items = ["*"]
    }
    access_control_expose_headers {
      items = ["Content-Length"]
    }
  }
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  is_ipv6_enabled = true
  http_version = "http2and3"
  price_class = "PriceClass_100"
  aliases = local.cdn_domain_names

  origin {
    origin_id = local.storage_origin_id
    domain_name = aws_s3_bucket.storage.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.storage.id
  }

  origin {
    origin_id = local.google_fonts_origin_id
    domain_name = "fonts.googleapis.com"
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  origin {
    origin_id = local.google_fonts_files_origin_id
    domain_name = "fonts.gstatic.com"
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  origin {
    origin_id = local.calendly_origin_id
    domain_name = "assets.calendly.com"
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id = local.storage_origin_id
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"
    compress = true
    cache_policy_id = aws_cloudfront_cache_policy.assets.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.cors.id
  }

  ordered_cache_behavior {
    path_pattern = "/gfonts/*"
    target_origin_id = local.google_fonts_origin_id
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"
    compress = true
    cache_policy_id = aws_cloudfront_cache_policy.assets.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.cors.id

    function_association {
      event_type = "viewer-request"
      function_arn = aws_cloudfront_function.strip_gfonts_prefix.arn
    }
  }

  ordered_cache_behavior {
    path_pattern = "/gfonts-files/*"
    target_origin_id = local.google_fonts_files_origin_id
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"
    compress = true
    cache_policy_id = aws_cloudfront_cache_policy.assets.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.cors.id

    function_association {
      event_type = "viewer-request"
      function_arn = aws_cloudfront_function.strip_gfonts_prefix.arn
    }
  }

  ordered_cache_behavior {
    path_pattern = "/calendly-widget.js"
    target_origin_id = local.calendly_origin_id
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"
    compress = true
    cache_policy_id = aws_cloudfront_cache_policy.assets.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.cors.id

    function_association {
      event_type = "viewer-request"
      function_arn = aws_cloudfront_function.calendly_widget.arn
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
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
