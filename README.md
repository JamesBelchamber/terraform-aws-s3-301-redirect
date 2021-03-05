S3 301 Redirect
===============

Easily create one or more 301 redirects, with support for HTTPS and IPv6.

```
module "www_redirect" {
  source          = "JamesBelchamber/s3-301-redirect/aws"
  target          = "target.yourzone.com"
  logging_bucket  = aws_s3_bucket.access-log-bucket.bucket_domain_name
  logging_prefix  = "target.yourzone.com/"
  sources = {
    "redirect.myzone.com"     = aws_route53_zone.myzone_com.id
    "redirect.theirzone.com"  = aws_route53_zone.theirzone_com.id
  }
}
```

You must run this module against the AWS provider in North Virginia (us-east-1) only; this module will fail in any other region.