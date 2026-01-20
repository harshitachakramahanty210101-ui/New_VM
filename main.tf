module "vpc" {
  source = "./modules/vpc"

  region       = var.region
  network_name = var.network_name
  subnet_name  = var.subnet_name
  subnet_cidr  = var.subnet_cidr
}

module "vm" {
  source = "./modules/vm"

  zone               = var.zone
  vm_name            = var.vm_name
  machine_type       = var.machine_type
  subnet_self_link   = module.vpc.subnet_self_link
}

module "loadbalancer" {
  source         = "./modules/loadbalancer"
  instance_group = module.vm.instance_group
}
