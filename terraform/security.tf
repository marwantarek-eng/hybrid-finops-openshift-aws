module "security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "finops-security-group"
  description = "Example security group"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    https = {
      from_port   = 5432
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "PostgreSQL access from OpenShift Local / Dev machine"
    }
  }

  egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  tags = {
    Environment = "dev"
  }
}
