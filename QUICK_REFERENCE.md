# Quick Reference - Private VM with Cloud NAT

## Essential Commands

### Initial Setup
```bash
# 1. Set project
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID

# 2. Enable APIs
gcloud services enable compute.googleapis.com servicenetworking.googleapis.com monitoring.googleapis.com logging.googleapis.com

# 3. Initialize Terraform
terraform init
```

### Deployment
```bash
# Plan deployment
terraform plan

# Deploy
terraform apply

# Get outputs
terraform output
```

### Access VM
```bash
# SSH via IAP (recommended)
gcloud compute ssh private-vm --zone=us-central1-a --tunnel-through-iap

# Copy files to VM
gcloud compute scp file.txt private-vm:/tmp/ --zone=us-central1-a --tunnel-through-iap

# Access via HTTP (load balancer)
curl http://$(terraform output -raw load_balancer_ip)
```

### Verify Deployment
```bash
# Check VM status
gcloud compute instances describe private-vm --zone=us-central1-a

# Check Cloud NAT
gcloud compute routers get-status cloud-router --region=us-central1

# View logs
gcloud compute instances get-serial-port-output private-vm --zone=us-central1-a
```

### Verify Cloud NAT (from inside VM)
```bash
# SSH into VM
gcloud compute ssh private-vm --zone=us-central1-a --tunnel-through-iap

# Check outbound IP (should match nat_ip_address from terraform output)
curl ifconfig.me
```

### Monitoring
```bash
# View NAT logs
gcloud logging read "resource.type=compute_router" --limit 50 --format=json

# View VM logs
gcloud logging read "resource.type=gce_instance" --limit 50

# Get VM status
gcloud compute instances list
```

### Cleanup
```bash
# Destroy all resources
terraform destroy

# Confirm: type 'yes'
```

---

## File Structure

```
New_VM/
├── providers.tf           # GCP provider config (project_id, region)
├── main.tf                # Module declarations
├── variables.tf           # Input variables
├── terraform.tfvars       # Variable values (EDIT THIS!)
├── output.tf              # Output values
├── README.md              # Overview & quick start
├── DEPLOYMENT_GUIDE.md    # Detailed deployment steps
├── .gitignore             # Git exclusions
└── modules/
    ├── vpc/               # VPC + Cloud NAT
    │   ├── main.tf        # VPC, Router, NAT, Firewall
    │   ├── variables.tf   # VPC variables
    │   └── output.tf      # VPC outputs
    ├── vm/                # Private VM
    │   ├── main.tf        # VM + Service Account + IAM
    │   ├── startup.sh     # VM initialization script
    │   ├── variables.tf   # VM variables
    │   └── output.tf      # VM outputs
    └── loadbalancer/      # HTTP Load Balancer
        ├── main.tf        # LB + Backend + Firewall
        ├── variables.tf   # LB variables
        └── output.tf      # LB outputs
```

---

## Key Terraform Files to Edit

### 1. terraform.tfvars (MUST EDIT!)
```hcl
project_id   = "YOUR_PROJECT_ID"       # REQUIRED!
region       = "us-central1"
zone         = "us-central1-a"
network_name = "private-vpc"
subnet_name  = "private-subnet"
subnet_cidr  = "10.0.1.0/24"
vm_name      = "private-vm"
machine_type = "e2-medium"
```

### 2. modules/vpc/main.tf
- VPC Network (private-vpc)
- Subnet (10.0.1.0/24)
- Cloud NAT with static IP
- Cloud Router
- Firewall rules (SSH, HTTP, HTTPS, internal)

### 3. modules/vm/main.tf
- Private VM instance (no external IP)
- Service Account with IAM roles
- Startup script (Nginx, monitoring)

### 4. modules/vm/startup.sh
- Updates packages
- Installs Nginx web server
- Configures health check page
- Installs Cloud Monitoring agent

### 5. modules/loadbalancer/main.tf
- Health check
- Backend service
- URL map
- HTTP proxy
- Global forwarding rule with static IP

---

## Architecture at a Glance

```
┌─────────────────────────────────────┐
│  Load Balancer (Public IP)          │ ← HTTP from internet
│                                      │
│  Backend Service                     │
│      ↓                               │
│  Health Check (HTTP:80)              │
│      ↓                               │
├─────────────────────────────────────┤
│  VPC: 10.0.1.0/24                   │
│  ┌─────────────────────────────────┐│
│  │ Private VM (10.0.1.2)           ││
│  │ - No external IP                ││
│  │ - Nginx on port 80              ││
│  │ - Outbound via Cloud NAT        ││
│  │                                 ││
│  │ Cloud NAT (Static IP: 34.71.x) ││ ← Outbound internet
│  │ Cloud Router                    ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

---

## Important Outputs

After `terraform apply`, get these values:

```bash
terraform output -raw vm_internal_ip          # Private VM's internal IP
terraform output -raw nat_ip_address          # Cloud NAT static IP
terraform output -raw load_balancer_ip        # Load Balancer public IP
terraform output -raw load_balancer_url       # HTTP access URL
```

---

## Security Features Implemented

✅ **Private VM** - No direct internet exposure  
✅ **Cloud NAT** - Outbound via static IP  
✅ **Firewall** - Ingress rules restrict access  
✅ **Service Account** - Least privilege IAM  
✅ **OS Login** - SSH key management  
✅ **Monitoring** - Cloud Logging & Monitoring  
✅ **Health Checks** - Automated VM monitoring  

---

## Cost Estimate (Monthly)

| Resource | Cost | Notes |
|----------|------|-------|
| Compute VM (e2-medium) | ~$30 | 730 hours/month |
| Cloud NAT (1 IP) | ~$32 | Static IP + data processing |
| Load Balancer | ~$16.50 | Forwarding rule |
| Data Transfer | Variable | Outbound traffic charges |
| Logging | <$1 | Minimal logs |
| **Total** | **~$80-120** | Varies by usage |

---

## Troubleshooting Quick Links

| Issue | Solution |
|-------|----------|
| Permission denied | `gcloud auth application-default login` |
| VM not starting | `gcloud compute instances get-serial-port-output` |
| Can't SSH | `gcloud compute ssh --tunnel-through-iap` |
| No internet access | `gcloud compute routers get-status cloud-router` |
| LB not working | Check firewall rules & VM health |

---

## Variables Reference

### Root Level (terraform.tfvars)
```hcl
project_id    - GCP Project ID (REQUIRED)
region        - GCP region (us-central1)
zone          - GCP availability zone (us-central1-a)
network_name  - VPC name (private-vpc)
subnet_name   - Subnet name (private-subnet)
subnet_cidr   - Subnet CIDR (10.0.1.0/24)
router_name   - Cloud Router name (cloud-router)
nat_name      - Cloud NAT name (cloud-nat)
vm_name       - VM instance name (private-vm)
machine_type  - VM size (e2-medium)
image_family  - OS image (ubuntu-2404-lts)
image_project - Image source (ubuntu-os-cloud)
```

---

## Getting Help

1. **Check Terraform state**: `terraform show`
2. **Validate syntax**: `terraform validate`
3. **View plan**: `terraform plan`
4. **Check GCP console**: https://console.cloud.google.com
5. **View logs**: `gcloud logging read --limit 50`

---

## Before You Start

- [ ] GCP account created with billing enabled
- [ ] `gcloud` CLI installed
- [ ] Terraform installed
- [ ] Authenticated: `gcloud auth application-default login`
- [ ] APIs enabled in GCP Console
- [ ] terraform.tfvars updated with your project_id

---

## One-Line Deployment (After Setup)

```bash
terraform init && terraform apply -auto-approve && echo "✅ Deployment complete!" && terraform output
```

---

## Important Notes

⭐ **Cloud NAT Pointer**: This configuration shows how a private VM (no external IP) uses Cloud NAT for outbound internet access while remaining secure and private. The VM is only accessible via Cloud IAP (SSH) or internal network, but can reach external services via the NAT gateway's static IP.

🔒 **Security**: In production, restrict SSH access by changing `source_ranges = ["0.0.0.0/0"]` in the SSH firewall rule to your IP: `source_ranges = ["YOUR_IP/32"]`

💰 **Costs**: Cloud NAT costs ~$32/month plus data transfer charges. Estimate costs before deploying at https://cloud.google.com/products/calculator

---

Last Updated: January 2026
