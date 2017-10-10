resource "aws_route53_record" "301" {
  zone_id = "${var.zone_id}"
  name    = "${var.name}"
  type    = "A"

  alias {
    name                   = "${aws_s3_bucket.301.website_domain}"
    zone_id                = "${aws_s3_bucket.301.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_s3_bucket" "301" {
  bucket = "${var.name}"

  website {
    redirect_all_requests_to = "${var.target}"
  }
}
