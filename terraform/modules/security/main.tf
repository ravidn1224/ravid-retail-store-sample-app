variable "vpc_id"       { type = string }
variable "project_name" { type = string }

# Common self traffic (node-to-node)
locals {
  kube_ports = [
    22,     
    6443,   
    2379,   
    2380,   
    10250,  
    30000,  
    32767   
  ]
}

resource "aws_security_group" "control_plane" {
  name        = "${var.project_name}-sg-control-plane"
  description = "Control plane security group"
  vpc_id      = var.vpc_id


  ingress { 
    from_port = 22   
    to_port = 22   
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
  ingress { 
    from_port = 6443 
    to_port = 6443 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress { 
    from_port = 2379 
    to_port = 2380 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
  ingress { 
    from_port = 10250 
    to_port = 10250 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress { 
    from_port = 30000 
    to_port = 32767 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  egress  { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  tags = { 
    Name = "${var.project_name}-sg-control-plane" 
    }
}

resource "aws_security_group" "worker" {
  name        = "${var.project_name}-sg-worker"
  description = "Worker node security group"
  vpc_id      = var.vpc_id

  ingress { 
    from_port = 22   
    to_port = 22    
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
  ingress { 
    from_port = 10250 
    to_port = 10250 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
  ingress { 
    from_port = 30000 
    to_port = 32767 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
  egress  { 
    from_port = 0     
    to_port = 0     
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  tags = { 
    Name = "${var.project_name}-sg-worker" 
    }
}

output "control_plane_sg_id" {
   value = aws_security_group.control_plane.id 
   }
output "worker_sg_id"        { 
  value = aws_security_group.worker.id 
  }
