variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "VPC Network Name"
  type        = string
  default     = "private-vpc"
}

variable "subnet_name" {
  description = "Subnet Name"
  type        = string
  default     = "private-subnet"
}

variable "subnet_cidr" {
  description = "Subnet CIDR Range"
  type        = string
  default     = "10.0.1.0/24"
}

variable "router_name" {
  description = "Cloud Router Name"
  type        = string
  default     = "cloud-router"
}

variable "nat_name" {
  description = "Cloud NAT Name"
  type        = string
  default     = "cloud-nat"
}

variable "vm_name" {
  description = "VM Instance Name"
  type        = string
  default     = "private-vm"
}

variable "machine_type" {
  description = "Machine Type"
  type        = string
  default     = "e2-medium"
}

variable "image_family" {
  description = "Image Family"
  type        = string
  default     = "ubuntu-2404-lts"
}

variable "image_project" {
  description = "Image Project"
  type        = string
  default     = "ubuntu-os-cloud"
}

variable "credentials"{
  type = string
}