provider "aws" {
 region = "us-east-1"
}

resource "aws_s3_bucket" "mynewbucket" {
 bucket = "yokeshdevops.mounickraj.com"
 versioning {
        enabled = true
 }
}

resource "aws_s3_bucket_ownership_controls" "ownership_control" {
  bucket = aws_s3_bucket.mynewbucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
 bucket = aws_s3_bucket.mynewbucket.id

 block_public_acls = false
 block_public_policy = false
 ignore_public_acls = false
 restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
                aws_s3_bucket_ownership_controls.ownership_control,
                aws_s3_bucket_public_access_block.public_access,
               ]

  bucket = aws_s3_bucket.mynewbucket.id
  acl    = "public-read"
}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.mynewbucket.id
  key    = "index.html"
  source = "index.html"
  acl = "public-read"
  content_type = "text/html"
}
resource "aws_s3_object" "error" {
  bucket = aws_s3_bucket.mynewbucket.id
  key    = "error.html"
  source = "error.html"
  acl = "public-read"
  content_type = "text/html"
}


resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.mynewbucket.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
  depends_on = [ aws_s3_bucket_acl.example ]
}

resource "aws_acm_certificate" "yokeshdevops" {
 domain_name  = "yokeshdevops.mounickraj.com"
 validation_method = "DNS"
}
 tags = {
        Name = "DNSCertificate"
 }resource "aws_cloudfront_distribution" "devOps_s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.mynewbucket.bucket_regional_domain_name
    origin_id                = "S3Origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"


  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
 tags = {
    Environment = "production"
  }
 viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.yokeshdevops.arn
    ssl_support_method = "sni-only"
    cloudfront_default_certificate = true
  }
  restrictions {
        geo_restriction {
                restriction_type = "none"
        }
 }
 aliases = ["yokeshdevops.mounickraj.com"]
 custom_error_response {
        error_code = 403
        response_code = 404
        response_page_path = "/error.html"
 }
}
