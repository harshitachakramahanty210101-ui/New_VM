# Deployment Guide: Private VM with Cloud NAT

## Overview

This guide walks you through deploying a production-ready private VM on Google Cloud Platform with Cloud NAT for secure internet access.

### What Gets Deployed

- **VPC Network** - Private network (10.0.1.0/24)
- **Private Subnet** - For VM and internal resources
- **Private VM** - Ubuntu 24.04 LTS with Nginx
- **Cloud NAT** - Outbound internet gateway with static IP
- **Cloud Router** - Manages NAT gateway
- **Load Balancer** - External HTTP access to private VM
- **Firewall Rules** - SSH, HTTP, HTTPS, internal communication
- **Service Account** - VM identity with logging/monitoring permissions
- **Cloud Monitoring** - Observability for VM health

---

## Step 1: Prerequisites

### Install Required Tools

```bash
# Install Terraform (macOS)
brew install terraform

# Install Terraform (Ubuntu/Debian)
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install gcloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Verify installations
terraform --version
gcloud --version
```

### Create/Select GCP Project

```bash
# Create a new project
gcloud projects create YOUR_PROJECT_ID --name="Private VM with NAT"

# Or set existing project
gcloud config set project YOUR_PROJECT_ID

# Enable billing (required!)
gcloud billing projects link YOUR_PROJECT_ID --billing-account=YOUR_BILLING_ACCOUNT
```

### Enable Required APIs

```bash
gcloud services enable compute.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### Setup Authentication

```bash
# Authenticate with Google Cloud
gcloud auth application-default login

# Verify authentication
gcloud auth list
```

---

## Step 2: Prepare Terraform Configuration

### Clone or Download Repository

```bash
git clone <repository-url>
cd New_VM
```

### Update Variables

Edit `terraform.tfvars`:

```hcl
project_id    = "your-actual-project-id"      # REQUIRED: Change this!
region        = "us-central1"                   # Change if desired
zone          = "us-central1-a"                 # Must match region
network_name  = "private-vpc"                   # VPC name
subnet_name   = "private-subnet"                # Subnet name
subnet_cidr   = "10.0.1.0/24"                   # Internal network range
router_name   = "cloud-router"                  # Cloud Router name
nat_name      = "cloud-nat"                     # NAT gateway name
vm_name       = "private-vm"                    # VM instance name
machine_type  = "e2-medium"                     # VM size
image_family  = "ubuntu-2404-lts"               # OS version
image_project = "ubuntu-os-cloud"               # Image source
```

### Review Module Structure

```
New_VM/
├── modules/
│   ├── vpc/
│   │   ├── main.tf          # VPC, NAT, Router
│   │   ├── variables.tf     # VPC variables
│   │   └── output.tf        # VPC outputs
│   ├── vm/
│   │   ├── main.tf          # Private VM definition
│   │   ├── startup.sh       # VM initialization script
│   │   ├── variables.tf     # VM variables
│   │   └── output.tf        # VM outputs
│   └── loadbalancer/
│       ├── main.tf          # Load balancer config
│       ├── variables.tf     # LB variables
│       └── output.tf        # LB outputs
├── main.tf                  # Root module
├── providers.tf             # Provider config
├── variables.tf             # Root variables
├── terraform.tfvars         # Variable values
├── output.tf                # Root outputs
├── .gitignore               # Git exclusions
└── README.md                # Documentation
```

---

## Step 3: Initialize Terraform

```bash
# Initialize Terraform working directory
terraform init

# This will:
# - Download Google provider
# - Create .terraform/ directory
# - Initialize Terraform state
```

Expected output:
```
Terraform has been successfully initialized!
```

---

## Step 4: Plan the Deployment

```bash
# Preview all changes
terraform plan -out=tfplan

# Review the plan carefully
# Should show creating:
# - google_compute_network.vpc
# - google_compute_subnetwork.subnet
# - google_compute_firewall rules (4)
# - google_compute_address.nat_ip
# - google_compute_router.router
# - google_compute_router_nat.nat
# - google_compute_instance.private_vm
# - google_compute_service_account.vm_sa
# - google_compute_global_address.lb_ip
# - google_compute_backend_service.default
# - etc.
```

### Review Plan Output

Look for:
- ✅ Correct project ID
- ✅ Correct region/zone
- ✅ All 20+ resources ready
- ✅ No resource deletions
- ✅ No sensitive data leakage

---

## Step 5: Apply Configuration

```bash
# Deploy all resources
terraform apply tfplan

# Or without plan file (interactive)
terraform apply

# When prompted: Review and type 'yes'
```

**Deployment Time**: 3-5 minutes

Expected completion:
```
Apply complete! Resources: XX added, 0 changed, 0 destroyed.
```

---

## Step 6: Retrieve Outputs

```bash
# Display all outputs
terraform output

# Save outputs to file
terraform output > outputs.txt

# Get specific outputs
terraform output -raw vm_internal_ip
terraform output -raw nat_ip_address
terraform output -raw load_balancer_ip
```

**Key Outputs:**
```
load_balancer_ip  = "34.102.156.xx"        # Public IP for HTTP
load_balancer_url = "http://34.102.156.xx" # Accessible URL
nat_ip_address    = "34.71.126.xx"         # Outbound IP (Cloud NAT)
vm_internal_ip    = "10.0.1.2"             # Private VM IP
vm_instance_id    = "1234567890123456789"  # VM ID
```

---

## Step 7: Access the Private VM

### Option A: SSH via Cloud IAP (Recommended)

```bash
# SSH through Identity-Aware Proxy (secure, no public IP needed)
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap

# Or with custom command
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command='uname -a'
```

### Option B: Copy Files

```bash
# Copy file to VM
gcloud compute scp local_file.txt private-vm:/tmp/ \
  --zone=us-central1-a \
  --tunnel-through-iap

# Copy file from VM
gcloud compute scp private-vm:/var/log/syslog ./local_syslog.txt \
  --zone=us-central1-a \
  --tunnel-through-iap
```

### Option C: Access via Load Balancer (HTTP)

```bash
# Get load balancer IP
LB_IP=$(terraform output -raw load_balancer_ip)

# Test HTTP access
curl http://$LB_IP

# Should see HTML page with VM information
```

---

## Step 8: Verify Cloud NAT Functionality

```bash
# SSH into VM
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap

# Inside VM, check outbound IP (should be Cloud NAT IP)
curl ifconfig.me
# Output: 34.71.126.xx (matches terraform output nat_ip_address)

# Test DNS resolution
nslookup google.com

# Check connectivity to external services
curl https://www.google.com

# View system information
cat /etc/os-release
cat /var/log/vm-startup.log
```

---

## Step 9: Monitor Resources

### Check VM Status

```bash
# Get VM details
gcloud compute instances describe private-vm \
  --zone=us-central1-a

# List all instances
gcloud compute instances list

# Get VM serial port output (startup logs)
gcloud compute instances get-serial-port-output private-vm \
  --zone=us-central1-a
```

### Check Cloud NAT Status

```bash
# View router status
gcloud compute routers describe cloud-router \
  --region=us-central1

# Get NAT status
gcloud compute routers get-status cloud-router \
  --region=us-central1
```

### View Logs

```bash
# View Cloud NAT logs
gcloud logging read \
  "resource.type=compute_router AND resource.labels.router_id=cloud-router" \
  --limit 50 \
  --format=json

# View VM system logs
gcloud logging read \
  "resource.type=gce_instance AND resource.labels.instance_id=<instance-id>" \
  --limit 50
```

---

## Step 10: Setup & Customization

### Modify Startup Script

Edit `modules/vm/startup.sh` to customize VM initialization:

```bash
#!/bin/bash
# Add custom commands here
apt-get install -y nginx  # Already installed
apt-get install -y docker.io  # Add Docker
# ... more customizations
```

Then re-deploy:
```bash
terraform apply
```

### Add More Firewall Rules

Edit `modules/vpc/main.tf` and add:

```hcl
resource "google_compute_firewall" "allow_custom" {
  name    = "private-vpc-allow-custom"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080", "8081", "8082"]  # Custom ports
  }

  source_ranges = ["0.0.0.0/0"]
}
```

### Scale VM Resources

Edit `terraform.tfvars`:

```hcl
machine_type = "e2-standard-2"  # Larger machine
```

Redeploy:
```bash
terraform apply
```

---

## Step 11: Security Hardening

### Restrict SSH Access (Production)

Edit `modules/vpc/main.tf`, change SSH rule:

```hcl
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.network_name}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["YOUR_IP/32"]  # Restrict to your IP
}
```

### Enable OS Login

Already configured, but verify:
```bash
gcloud compute project-info describe \
  --format='value(commonInstanceMetadata.items[OS_LOGIN_ENABLED])'
```

### Review IAM Permissions

```bash
gcloud projects get-iam-policy $PROJECT_ID
gcloud service-accounts list
gcloud service-accounts get-iam-policy private-vm-sa@$PROJECT_ID.iam.gserviceaccount.com
```

---

## Step 12: Cost Monitoring

### Check Current Charges

```bash
# View Google Cloud billing
gcloud billing budgets list
```

### Set Budget Alert

```bash
# Go to GCP Console → Billing → Budgets & alerts
# Set alert at 80% of estimated monthly spend
```

### Estimate Costs

```
Monthly costs (e2-medium in us-central1):
- Compute VM:      ~$30
- Cloud NAT:       ~$32 + data transfer
- Load Balancer:   ~$16.50 + data ingress
- Cloud Logging:   ~$0.50
- Cloud Monitoring: ~$1
─────────────────────────────
TOTAL:             ~$80-120/month
```

---

## Step 13: Maintenance

### Update OS Packages

```bash
# SSH into VM
gcloud compute ssh private-vm --zone=us-central1-a --tunnel-through-iap

# Inside VM:
sudo apt-get update
sudo apt-get upgrade -y
```

### Backup VM Image

```bash
# Create VM image for backup
gcloud compute images create private-vm-backup-$(date +%Y%m%d) \
  --source-disk=private-vm \
  --source-disk-zone=us-central1-a
```

### View Terraform State

```bash
# Check current state
terraform show

# Validate configuration
terraform validate
```

---

## Step 14: Cleanup & Destroy

### Backup Before Destroying

```bash
# Export Terraform state
terraform show > terraform-backup.txt

# Export outputs
terraform output > outputs-backup.json
```

### Destroy All Resources

```bash
# Preview destruction
terraform plan -destroy

# Destroy all resources (takes 2-3 minutes)
terraform destroy

# Confirm: type 'yes'
```

This will delete:
- ✓ Private VM
- ✓ VPC and Subnet
- ✓ Cloud NAT and Router
- ✓ Load Balancer
- ✓ Firewall Rules
- ✓ Static IPs
- ✓ Service Account

---

## Troubleshooting

### Error: "Permission denied"

```bash
# Check authentication
gcloud auth list

# Re-authenticate
gcloud auth application-default login

# Set project
gcloud config set project YOUR_PROJECT_ID
```

### Error: "Quota exceeded"

```bash
# Check quotas
gcloud compute project-info describe \
  --format='value(quotas[].metric)'

# Request quota increase in GCP Console
```

### VM Not Starting

```bash
# Check serial port output
gcloud compute instances get-serial-port-output private-vm \
  --zone=us-central1-a | tail -50

# Check metadata
gcloud compute instances describe private-vm \
  --zone=us-central1-a \
  --format='value(metadata)'
```

### Can't SSH to VM

```bash
# Test IAP tunnel
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --v

# Check IAM bindings
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.role:compute.osLogin"
```

### Load Balancer Not Working

```bash
# Check backend service health
gcloud compute backend-services get-health nginx-backend-service

# Check forwarding rule
gcloud compute forwarding-rules list

# Check VM firewall rules
gcloud compute firewall-rules list --filter="network:private-vpc"
```

---

## Next Steps

1. **Setup HTTPS**: Add SSL certificate to load balancer
2. **Enable Autoscaling**: Use instance group autoscaler
3. **Add Database**: Deploy Cloud SQL in same VPC
4. **Setup CI/CD**: Deploy Terraform via Cloud Build
5. **Multi-Region**: Replicate setup in additional regions
6. **Disaster Recovery**: Implement backup and restore procedures

---

## Support Resources

- [Terraform Google Provider Docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP Cloud NAT Documentation](https://cloud.google.com/nat/docs/overview)
- [Private Google Cloud VMs](https://cloud.google.com/vpc/docs/special-configurations)
- [Cloud IAP Documentation](https://cloud.google.com/iap/docs)
- [GCP Pricing Calculator](https://cloud.google.com/products/calculator)

---

**Last Updated**: January 2026  
**Terraform Version**: >= 1.0  
**GCP Provider**: ~> 5.0
