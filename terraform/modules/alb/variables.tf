variable "name" {
  description = "Project prefix"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "worker_instance_ids" {
  type        = list(string)
  description = "EC2 worker node IDs to attach to ALB"
}

variable "target_port" {
  description = "Port exposed on workers (NodePort)"
  type        = number
  default     = 30080
}

variable "health_check_path" {
  type    = string
  default = "/health"
}
