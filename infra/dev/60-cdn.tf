data "aws_cloudfront_cache_policy" "cachingOptmized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "cachingDisabled" {
  name = "Managed-CachingDisabled"
}

# ====================================================== #
# CLOUDFRONT VPC ORIGIN
# INTERNAL APPLICATION LOAD BALANCER
# ====================================================== #
resource "aws_cloudfront_vpc_origin" "internal_alb" {

  vpc_origin_endpoint_config {
    name = "roboshop-dev-internal-alb-vpc-origin"

    # Existing internal ALB ARN
    arn = module.alb.alb_arn

    # ALB listener ports
    http_port  = 80
    https_port = 443

    # CloudFront communicates with ALB using HTTP
    origin_protocol_policy = "http-only"

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "roboshop-dev-internal-alb-vpc-origin"
    }
  )
}

# ============================================================== #
# Create Cloudfront Distribution                                 #
# ============================================================== #
resource "aws_cloudfront_distribution" "roboshop" {
  enabled             = true
  is_ipv6_enabled     = false
  comment             = "Roboshop Cloudfront Distribution"
  
  # ORIGIN: Internal ALB VPC Origin
  origin {
    domain_name = module.alb.alb_dns_name                                              # "${var.project}-${var.env}.${var.domain_name}"
    origin_id   = "${var.project}-${var.env}-internal-alb-origin"                      # roboshop-dev-internal-alb-origin

  vpc_origin_config {
      vpc_origin_id = aws_cloudfront_vpc_origin.internal_alb.id                        # This sets VPC origin as origin to Cloudfront Distribution
    }

    # This setting is for external ALB
    # custom_origin_config {
    #   http_port              = 80
    #   https_port             = 443
    #   origin_protocol_policy = "https-only" # Enforce HTTPS to ALB
    #   origin_ssl_protocols   = ["TLSv1.2"]
    # }
  }
  
  # CDN name
  # aliases = ["${var.project}-cdn.${var.domain_name}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.project}-${var.env}-internal-alb-origin"                 # roboshop-dev-internal-alb-origin

    viewer_protocol_policy = "redirect-to-https"                                       # "https-only"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    cache_policy_id = data.aws_cloudfront_cache_policy.cachingDisabled.id              # local.cachingDisabled
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/media/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "${var.project}-${var.env}-internal-alb-origin"                 # roboshop-dev-internal-alb-origin

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"      # "https-only"
    cache_policy_id = data.aws_cloudfront_cache_policy.cachingOptmized.id              # local.cachingOptmized
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/videos/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "${var.project}-${var.env}-internal-alb-origin"                 # roboshop-dev-internal-alb-origin

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"                                       # "https-only"
    cache_policy_id = data.aws_cloudfront_cache_policy.cachingOptmized.id              # local.cachingOptmized
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
      #locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = merge(
    {
        Name = "${var.project}-${var.env}"
    },
    local.common_tags
  )

  # viewer_certificate {
  #   acm_certificate_arn = local.certificate_arn
  #   ssl_support_method  = "sni-only"
  # }
}

# resource "aws_route53_record" "www" {
#   zone_id = var.zone_id
#   name    = "${var.project}-cdn.daws90s.shop" # *.daws90s.shop
#   type    = "A"

#   alias {
#     # AWS details
#     name                   = aws_cloudfront_distribution.roboshop.domain_name
#     zone_id                = aws_cloudfront_distribution.roboshop.hosted_zone_id
#     evaluate_target_health = true
#   }
#   allow_overwrite = true
# }
