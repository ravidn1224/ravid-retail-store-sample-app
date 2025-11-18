output "vpc_id"                     { value = module.vpc.vpc_id }
output "public_subnet_ids"          { value = module.vpc.public_subnet_ids }
output "control_plane_public_ip"    { value = module.ec2.control_plane_public_ip }
output "worker_public_ips"          { value = module.ec2.worker_public_ips }
output "ecr_repositories"           { value = module.ecr.repo_urls }
output "instance_profile_name"      { value = module.iam.instance_profile_name }
