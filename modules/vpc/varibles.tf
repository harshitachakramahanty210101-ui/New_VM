variable "network_name" {
  type        = string
  description = "Name of the custom VPC"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR range for subnet"
}

variable "region" {
  type        = string
  description = "Region for subnet and NAT"
}