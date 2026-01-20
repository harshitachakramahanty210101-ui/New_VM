# 🔧 Troubleshooting & Common Issues Guide

---

## Common Issues & Solutions

### Issue 1: "Error: Error when reading or editing Terraform State for module: googleapi: Error 403"

**Cause**: Missing GCP API enablement or insufficient permissions

**Solution**:
```bash
# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com

# Check IAM permissions
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="members:$(gcloud config get-value account)"
```

---

### Issue 2: "terraform.tfvars: FAILED - project_id variable not set"

**Cause**: Missing project_id in terraform.tfvars

**Solution**:
```bash
# Edit terraform.tfvars and set:
project_id = "your-actual-project-id"

# Verify:
grep project_id terraform.tfvars
```

**Check**:
```bash
# Get your actual project ID
gcloud config get-value project
```

---

### Issue 3: "Error: google_compute_instance: Error creating instance: googleapi: Error 403: Quota exceeded"

**Cause**: Resource quota exceeded in your GCP project

**Solution**:
```bash
# Check current quotas
gcloud compute project-info describe \
  --format='value(quotas[].metric)'

# View quota usage
gcloud compute project-info describe \
  --project=$PROJECT_ID \
  --format='table(quotas[].metric, quotas[].usage, quotas[].limit)'

# Request quota increase in GCP Console:
# Navigation: IAP → Quotas & System limits
```

---

### Issue 4: "Can't SSH into private VM - Permission denied"

**Cause**: IAM permissions or OS Login not configured

**Solution**:
```bash
# Verify OS Login is enabled
gcloud compute project-info describe \
  --format='value(commonInstanceMetadata.items[OS_LOGIN_ENABLED])'

# Enable OS Login
gcloud compute instances add-metadata private-vm \
  --zone=us-central1-a \
  --metadata=enable-oslogin=TRUE

# Check your SSH key setup
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Try SSH again
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap
```

---

### Issue 5: "SSH Connection refused / timeout"

**Cause**: Cloud IAP not configured or VM startup incomplete

**Solution**:
```bash
# Check VM status
gcloud compute instances describe private-vm \
  --zone=us-central1-a \
  --format='value(status)'

# Wait for VM to fully start (check startup logs)
gcloud compute instances get-serial-port-output private-vm \
  --zone=us-central1-a

# If status is RUNNING but can't SSH, wait 2-3 minutes for startup script

# Test basic connectivity
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command='whoami'
```

---

### Issue 6: "No internet access from VM"

**Cause**: Cloud NAT not properly configured or VM subnet not included

**Solution**:
```bash
# From inside VM:
# Test DNS
nslookup google.com

# Test outbound connectivity
curl -v ifconfig.me

# Check NAT status
gcloud compute routers get-status cloud-router \
  --region=us-central1

# Verify NAT gateway is active
gcloud compute routers nats describe cloud-nat \
  --router=cloud-router \
  --region=us-central1
```

**From your local machine**:
```bash
# Troubleshoot routing
gcloud compute routers describe cloud-router \
  --region=us-central1

# Check firewall rules
gcloud compute firewall-rules list --filter="network:private-vpc"
```

---

### Issue 7: "Load Balancer not serving traffic / 502 Bad Gateway"

**Cause**: Backend health check failing or VM not responding

**Solution**:
```bash
# Check backend health
gcloud compute backend-services get-health nginx-backend-service

# SSH into VM and verify Nginx
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command='sudo systemctl status nginx'

# Check Nginx logs
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command='sudo tail -20 /var/log/nginx/error.log'

# Verify HTTP port is open
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command='netstat -tlnp | grep :80'

# Manually test port 80
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command='curl localhost'
```

---

### Issue 8: "Terraform state corruption / lock timeout"

**Cause**: Incomplete operation or multiple simultaneous runs

**Solution**:
```bash
# Check state lock
ls -la .terraform/

# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>

# Refresh state
terraform refresh

# Validate configuration
terraform validate

# Re-plan
terraform plan -refresh=true
```

---

### Issue 9: "Changes to output variables not reflecting"

**Cause**: Terraform state out of sync with actual resources

**Solution**:
```bash
# Refresh state
terraform refresh

# Get outputs
terraform output

# Or specific output
terraform output -raw nat_ip_address

# Check actual resource in GCP
gcloud compute addresses list --filter="name:cloud-nat-ip"
```

---

### Issue 10: "Persistent disk attachment errors"

**Cause**: Disk already in use or region mismatch

**Solution**:
```bash
# Check disk status
gcloud compute disks list --zones us-central1-a

# Verify region matches zone
gcloud compute instances describe private-vm \
  --zone=us-central1-a \
  --format='value(zone)'

# For corrupted disks, create new boot disk
gcloud compute disks create private-vm-backup \
  --image-family=ubuntu-2404-lts \
  --image-project=ubuntu-os-cloud \
  --zone=us-central1-a
```

---

## Advanced Troubleshooting

### Check Terraform Logs
```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform apply

# Save logs to file
export TF_LOG_PATH=/tmp/terraform.log
terraform plan

# View logs
cat /tmp/terraform.log
```

### Validate GCP Resources
```bash
# List all VPCs
gcloud compute networks list

# List all VMs
gcloud compute instances list

# List all routers
gcloud compute routers list

# List all NATs
gcloud compute routers nats list --router=cloud-router --region=us-central1

# List all firewall rules
gcloud compute firewall-rules list --filter="network:private-vpc"

# List all load balancers
gcloud compute forwarding-rules list
```

### Check IAM Permissions
```bash
# Get your current user
gcloud config get-value account

# Check service account permissions
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:*"

# Grant required role
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:private-vm-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"
```

### Monitor Logs in Real Time
```bash
# Watch Cloud NAT logs
gcloud logging read \
  "resource.type=compute_router" \
  --limit 50 \
  --tail

# Watch VM logs
gcloud logging read \
  "resource.type=gce_instance AND resource.labels.instance_id=<ID>" \
  --limit 50 \
  --tail

# Filter by severity
gcloud logging read "severity=ERROR" --limit 20
```

---

## Performance Issues

### High Network Latency
```bash
# Check NAT connection tracking
gcloud compute routers get-status cloud-router \
  --region=us-central1 | grep -i connection

# Check firewall rules overhead
gcloud compute firewall-rules describe private-vpc-allow-internal

# Test direct connectivity
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command='ping 8.8.8.8 -c 4'
```

### High CPU Usage
```bash
# SSH and check processes
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap

# Inside VM:
top -b -n 1 | head -20
ps aux --sort=-%cpu | head -10
```

### Disk Space Issues
```bash
# Check disk usage
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command='df -h'

# Increase disk size (requires VM stop)
gcloud compute disks resize private-vm \
  --size=50GB \
  --zone=us-central1-a

gcloud compute instances stop private-vm --zone=us-central1-a
gcloud compute instances start private-vm --zone=us-central1-a
```

---

## Recovery Procedures

### VM Unresponsive
```bash
# Hard reboot
gcloud compute instances stop private-vm \
  --zone=us-central1-a

# Wait 30 seconds
sleep 30

# Restart
gcloud compute instances start private-vm \
  --zone=us-central1-a
```

### Restore from Backup
```bash
# Create image backup
gcloud compute images create private-vm-backup-$(date +%s) \
  --source-disk=private-vm \
  --source-disk-zone=us-central1-a

# Create VM from backup image
gcloud compute instances create private-vm-restored \
  --zone=us-central1-a \
  --image=<backup-image-name> \
  --subnet=private-subnet \
  --no-address
```

### Partial Terraform Destroy & Rebuild
```bash
# Destroy only VM
terraform destroy -target=module.vm

# Rebuild only VM
terraform apply -target=module.vm
```

---

## Debugging Network Issues

### Trace Packet Flow
```bash
# From VM, trace route to external service
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command='traceroute 8.8.8.8'

# Check IP routing table
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command='ip route show'

# DNS troubleshooting
gcloud compute ssh private-vm \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command='nslookup -debug google.com'
```

### VPC Flow Logs
```bash
# Enable flow logs
gcloud compute networks subnets update private-subnet \
  --region=us-central1 \
  --enable-flow-logs

# View flow logs
gcloud logging read "resource.type=gce_subnetwork_flow_logs" \
  --limit 50 \
  --format=json
```

---

## Cost Issues

### Unexpected Charges
```bash
# Check NAT data processing
gcloud compute routers get-status cloud-router \
  --region=us-central1

# Identify high-traffic resources
gcloud monitoring time-series list \
  --filter='resource.type=compute_router'

# List all static IPs
gcloud compute addresses list --format='table(name,address,status)'

# Check load balancer usage
gcloud compute forwarding-rules list --format='table(name,IPAddress,target)'
```

### Cost Optimization
```bash
# Downsize VM
# Edit terraform.tfvars: machine_type = "e2-small"
terraform apply -target=module.vm

# Remove unused load balancer
terraform destroy -target=module.loadbalancer

# Downsize disk
# Note: Requires stopping VM first
gcloud compute instances stop private-vm --zone=us-central1-a
gcloud compute disks resize private-vm --size=10GB --zone=us-central1-a
gcloud compute instances start private-vm --zone=us-central1-a
```

---

## Quick Debug Checklist

- [ ] Verify project_id set correctly: `gcloud config get-value project`
- [ ] APIs enabled: `gcloud services list --enabled`
- [ ] VM running: `gcloud compute instances describe private-vm --zone=us-central1-a`
- [ ] NAT active: `gcloud compute routers get-status cloud-router --region=us-central1`
- [ ] Firewall open: `gcloud compute firewall-rules list --filter="network:private-vpc"`
- [ ] IAM roles: `gcloud projects get-iam-policy $PROJECT_ID | grep -i compute`
- [ ] Terraform state: `terraform show | head -20`
- [ ] Cloud logs: `gcloud logging read --limit 10`

---

## Still Not Working?

1. **Check GCP Console** - https://console.cloud.google.com
   - Compute Engine → VM instances
   - VPC Network → Routes
   - Networking → Cloud NAT

2. **Run terraform validate**
   ```bash
   terraform validate
   ```

3. **Check for errors**
   ```bash
   terraform plan 2>&1 | grep -i error
   ```

4. **Review startup script output**
   ```bash
   gcloud compute instances get-serial-port-output private-vm \
     --zone=us-central1-a \
     --port=1 | tail -100
   ```

5. **Consult Terraform docs**
   - https://www.terraform.io/docs
   - https://registry.terraform.io/providers/hashicorp/google/latest/docs

6. **Check GCP IAM permissions**
   - https://cloud.google.com/iam/docs/understanding-service-accounts
   - https://cloud.google.com/compute/docs/access-control/iam

---

**Last Updated**: January 2026  
**Terraform Version**: >= 1.0  
**GCP Provider**: ~> 5.0
