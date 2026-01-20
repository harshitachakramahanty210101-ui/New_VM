# Private VM with Cloud NAT - Terraform Configuration

This Terraform configuration deploys a **private VM on Google Cloud Platform (GCP)** with **Cloud NAT** for secure outbound internet access.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Google Cloud Project                      │
├─────────────────────────────────────────────────────────────┤
│  Cloud NAT (Static IP)                                       │
│      ↓                                                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ VPC Network (10.0.1.0/24)                            │   │
│  │  ┌────────────────────────────────────────────────┐  │   │
│  │  │ Subnet (Private)                               │  │   │
│  │  │  ┌───────────────────────────────────────────┐ │  │   │
│  │  │  │ Private VM (No External IP)               │ │  │   │
│  │  │  │ - Internal IP: 10.0.1.x                   │ │  │   │
│  │  │  │ - Outbound Internet: via Cloud NAT        │ │  │   │
│  │  │  │ - Inbound Access: IAP/Internal Network    │ │  │   │
│  │  │  │ - Services: Nginx, Cloud Logging/Monitor  │ │  │   │
│  │  │  └───────────────────────────────────────────┘ │  │   │
│  │  │  ┌───────────────────────────────────────────┐ │  │   │
│  │  │  │ Cloud Router → NAT                        │ │  │   │
│  │  │  │ (Manages outbound connections)            │ │  │   │
│  │  │  └───────────────────────────────────────────┘ │  │   │
│  │  └────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  Load Balancer (External)                                   │
│      ↓                                                       │
│  Public IP → Backend Service → Private VM                   │
└─────────────────────────────────────────────────────────────┘
```

## Key Features

✅ **Private VM** - No external IP, enhanced security
✅ **Cloud NAT** - Secure outbound internet access via static IP
✅ **Cloud Router** - Manages NAT gateway
✅ **Firewall Rules** - SSH, HTTP, HTTPS, Internal communication
✅ **Nginx Server** - Pre-configured web server
✅ **Service Account** - IAM roles for logging & monitoring
✅ **Cloud Monitoring** - Built-in observability
✅ **Cloud IAP** - Secure access to private VM
✅ **Load Balancer** - External traffic routing to private VM

## Prerequisites

- Google Cloud Platform (GCP) account with active billing
- `gcloud` CLI installed and authenticated
- Terraform >= 1.0
- Appropriate IAM permissions:
  - `roles/compute.admin`
  - `roles/iam.serviceAccountAdmin`
  - `roles/servicenetworking.admin`

## Quick Start

### 1. Update terraform.tfvars
```bash
project_id   = "your-project-id"
region       = "us-central1"
zone         = "us-central1-a"
```

### 2. Enable GCP APIs
```bash
gcloud services enable compute.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com
```

### 3. Deploy
```bash
terraform init
terraform plan
terraform apply
```

### 4. Access Outputs
```bash
terraform output
```

## Accessing the Private VM

### Via Cloud IAP (SSH)
```bash
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap
```

### Via Load Balancer (HTTP)
```bash
curl http://$(terraform output -raw load_balancer_ip)
```

## Verify Cloud NAT

SSH into VM and test outbound internet:
```bash
curl ifconfig.me
# Shows the Cloud NAT static IP address
```

## Cleanup

```bash
terraform destroy
```

## File Structure

```
.
├── main.tf                      # Root module
├── providers.tf                 # GCP provider
├── variables.tf                 # Variables
├── terraform.tfvars             # Variable values
├── output.tf                    # Outputs
└── modules/
    ├── vpc/                     # VPC with Cloud NAT
    ├── vm/                      # Private VM
    └── loadbalancer/            # Load Balancer
```

## Important: Cloud NAT Pointer ⭐

This configuration demonstrates deploying a **private VM using Cloud NAT for internet access**:

1. **Private VM**: No external/public IP assigned
2. **Cloud NAT**: Provides outbound internet via static IP
3. **Cloud Router**: Manages NAT gateway
4. **Secure Access**: Via Cloud IAP or internal network only
5. **Public Services**: Load Balancer enables HTTP/HTTPS access while VM stays private

## Security Features

- Private VM with no direct internet exposure
- Cloud NAT masks VM behind static IP for outbound connections
- IAM service account with minimal permissions
- OS Login for secure SSH access
- Firewall rules restrict ingress
- Cloud Monitoring and Logging enabled

## Cost Estimation

Monthly costs (approx):
- Compute VM (e2-medium): ~$30
- Cloud NAT: ~$32 + data costs
- Load Balancer: ~$16.50 + ingress costs
- **Total**: ~$80-150/month

## Troubleshooting

**SSH not working?**
```bash
gcloud compute ssh private-vm --zone=us-central1-a --tunnel-through-iap
```

**Check NAT status:**
```bash
gcloud compute routers get-status cloud-router --region=us-central1
```

**View startup logs:**
```bash
gcloud compute instances get-serial-port-output private-vm --zone=us-central1-a
```

## References

- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest)
- [Cloud NAT Documentation](https://cloud.google.com/nat/docs)
- [Private GCP VMs](https://cloud.google.com/vpc/docs/special-configurations)

---

**Version**: 1.0  
**Terraform**: >= 1.0  
**GCP Provider**: ~> 5.0