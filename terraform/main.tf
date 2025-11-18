module "vpc" {
  source         = "./modules/vpc"
  project_name   = var.project_name
  vpc_cidr       = var.vpc_cidr
  public_subnets = var.public_subnets
  azs            = var.azs
}

module "security" {
  source       = "./modules/security"
  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
  repos        = ["ui", "catalog", "cart", "orders", "checkout"]
}

module "ec2" {
  source                    = "./modules/ec2"
  project_name              = var.project_name
  ubuntu_ami                = var.ubuntu_ami
  key_pair_name             = var.key_pair_name
  public_subnet_ids         = module.vpc.public_subnet_ids
  control_plane_sg_id       = module.security.control_plane_sg_id
  worker_sg_id              = module.security.worker_sg_id
  instance_profile_name     = module.iam.instance_profile_name
  control_plane_instance_type = var.control_plane_instance_type
  worker_instance_type        = var.worker_instance_type
  worker_count                = var.worker_count
}
