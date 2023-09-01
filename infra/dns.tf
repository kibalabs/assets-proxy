
data "aws_route53_zone" "kibadev" {
  name = "kiba.dev"
}

resource "aws_route53_record" "kibadev_cdn" {
  zone_id = data.aws_route53_zone.kibadev.zone_id
  type = "A"
  name = "assets-cdn"
  alias {
    name = aws_cloudfront_distribution.cdn.domain_name
    zone_id = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = true
  }
}
