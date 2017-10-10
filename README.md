S3 301 Redirect
===============

Easily create a 301 redirect using an S3 bucket and a Route53 A record.

```
module "www_redirect" {
  source  = "JamesBelchamber/s3-301-redirect/aws"
  zone_id = "${aws_route53_zone.yourzone_com.zone_id}"
  name    = "${aws_route53_zone.yourzone_com.name}"
  target  = "www.${aws_route53_zone.yourzone_com.name}"
}
```
