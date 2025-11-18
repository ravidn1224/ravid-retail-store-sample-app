variable "region" { 
  type = string  
  default = "eu-central-1" 
  }

variable "project_name" { 
  type = string 
  default = "ravid-retail-store" 
  }

variable "vpc_cidr" { 
  type = string 
  default = "10.0.0.0/16" 
  }

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "azs" {
  type    = list(string)
  default = ["eu-central-1a","eu-central-1b"]
}

variable "key_pair_name" {
  description = "Existing AWS key pair name for SSH"
  type        = string
  default    = "ravid"
}

variable "control_plane_instance_type" { 
  type = string 
  default = "t2.medium" 
  }
variable "worker_instance_type"        { 
  type = string 
  default = "t2.medium" 
  }
variable "worker_count"                { 
  type = number 
  default = 2 
  }


variable "ubuntu_ami" {
  type        = string
  description = "Ubuntu Server 22.04 LTS AMI ID"
  default     = "ami-0a854fe96e0b45e4e" 
}
