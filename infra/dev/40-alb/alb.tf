# Security Group for ALB
module "alb_sg" {
  source = "git::https://github.com/vaheedgit26/Infra-1.0.git//modules/sg"

  vpc_id         = module.vpc.vpc_id
  sg_name        = local.alb_sg_name
  sg_description = "ALB Security Group"

  common_tags    = local.common_tags
}

# Retrieve AWS-managed CloudFront prefix list
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# Allow HTTP traffic from CloudFront to Internal ALB
resource "aws_security_group_rule" "cloudfront_to_alb" {
  description = "Allow HTTP traffic from CloudFront origin-facing servers"

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"

  security_group_id = module.alb_sg.sg_id
  prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
}

# Allow ALB traffic to frontend microservice in EKS (8080)
resource "aws_security_group_rule" "alb_to_eks_nodegroup" {
  description = "Allow ALB traffic to frontend microservice"
  # for_each = local.microservices

  type                     = "ingress"
  from_port                = 8080   # each.value.port
  to_port                  = 8080   # each.value.port
  protocol                 = "tcp"

  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.alb_sg.sg_id

  # description = "Allow ALB traffic to ${each.key} microservice"
}

# ALB Module Calling
module "alb" {
  source = "git::https://github.com/vaheedgit26/Infra-1.0.git//modules/alb"

  alb_name     = "${local.resource_name}-alb"
  internal     = true
  alb_sg_ids   = [module.alb_sg.sg_id]
  subnets      = module.vpc.private_subnet_ids 

  target_type  = "ip"
  vpc_id       = module.vpc.vpc_id

  listener_mode = "http"    # https, http_to_https
  # acm_certificate_arn = var.acm_certificate_arn

  services = local.microservices

  project      = var.project
  env          = var.env
  common_tags  = local.common_tags

  depends_on = [
    module.alb_sg,
    aws_security_group.cloudfront_to_alb,
    aws_security_group_rule.alb_to_eks_nodegroup  
  ]
}

############################################
# CLOUDFRONT VPC ORIGIN
# INTERNAL APPLICATION LOAD BALANCER
############################################

resource "aws_cloudfront_vpc_origin" "internal_alb" {

  vpc_origin_endpoint_config {

    name = "ecommerce-dev-internal-alb-vpc-origin"

    # Existing internal ALB ARN
    arn = aws_lb.internal_alb.arn

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
      Name = "ecommerce-dev-internal-alb-vpc-origin"
    }
  )

}
