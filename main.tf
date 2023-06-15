resource "aws_s3_bucket" "s3" {
  bucket = "cloud-resume-challenge-kausic"
}
# resource "aws_s3_object" "obj" {
#   bucket = "cloud-resume-challenge-kausic-new"
#   key="index.html"
#   source ="/Users/kausic/Desktop/CloudResumeChallenge/index.html"
# }
locals {
  content_type_map = {
   "js" = "application/json"
   "html" = "text/html"
   "css"  = "text/css"
   "pdf" = "application/pdf"
   "jpg" ="image/jpeg"
   "JPG" = "image/jpeg"
   "png" = "image/png"
  }
  s3_origin_id = "myS3Origin"
}


resource "aws_s3_object" "obj" {
  for_each = fileset("static/","**")
  bucket = aws_s3_bucket.s3.bucket
  key=each.value
  content_type = lookup(local.content_type_map, split(".", "static/${each.value}")[1], "text/html")
  source ="static/${each.value}"
  etag = filemd5("static/${each.value}")
}

# resource "aws_s3_object" "delobj" {
#   bucket = aws_s3_bucket.s3.bucket
#   key="images/.DS_Store"
# }
resource "aws_cloudfront_origin_access_control" "example" {
  name                              = "example"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
  data "aws_acm_certificate" "issued" {
  domain   = var.certificate_issued_domain
} 
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.s3.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.example.id
  }

  enabled             = true
  default_root_object = "index.html"

  aliases = [var.subdomain]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    viewer_protocol_policy = "redirect-to-https"
    compress = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = "production"
  }
  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.issued.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${self.id} --paths '/*'"
  }
}
resource "aws_s3_bucket_policy" "b" {
  bucket = aws_s3_bucket.s3.id

  policy = <<POLICY
{
        "Version": "2008-10-17",
        "Id": "PolicyForCloudFrontPrivateContent",
        "Statement": [
            {
                "Sid": "AllowCloudFrontServicePrincipal",
                "Effect": "Allow",
                "Principal": {
                    "Service": "cloudfront.amazonaws.com"
                },
                "Action": "s3:GetObject",
                "Resource": "${aws_s3_bucket.s3.arn}/*",
                "Condition": {
                    "StringEquals": {
                      "AWS:SourceArn": "${aws_cloudfront_distribution.s3_distribution.arn}"
                    }
                }
            }
        ]
      }
POLICY
}
data "aws_route53_zone" "myzone" {
  name         = var.domain_name
}
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.myzone.zone_id
  name    = "portfolio.kausicmn.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

