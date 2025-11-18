variable "project_name" { type = string }
variable "repos"        { type = list(string) }

resource "aws_ecr_repository" "repos" {
  for_each             = toset(var.repos)
  name                 = "${var.project_name}-${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration { scan_on_push = true }

  tags = {
    Name = "${var.project_name}-${each.value}"
  }
}

output "repo_urls" {
  value = { for k, r in aws_ecr_repository.repos : k => r.repository_url }
}
