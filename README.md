# DevOps Exercise — AWS Terraform Cluster

Infrastructure exercise deploying N web servers behind an AWS Application Load Balancer, managed with Terraform.

---

## Architecture
Internet
│
▼
Application Load Balancer (ALB)
│ round-robin
├──────────────┐
▼ ▼
web-server-1 web-server-2
(EC2 t3.micro) (EC2 t3.micro)
(nginx) (nginx)


---

## Prerequisites

- AWS account with credentials configured
- Terraform >= 1.5.0
- AWS CLI >= 2.x
- Git

---

## Quick Start

### 1. Clone the repository
```bash
git clone https://github.com/adirnago/devops-exercise.git
cd devops-exercise
```

### 2. Configure AWS credentials
```bash
aws configure
```

### 3. Install dependencies
```bash
chmod +x cluster.sh
./cluster.sh install
```

### 4. Deploy the cluster
```bash
./cluster.sh start
```

---

## Shell Script

```bash
./cluster.sh install   # Install dependencies + terraform init
./cluster.sh start     # Deploy the cluster (terraform apply)
./cluster.sh stop      # Destroy the cluster (terraform destroy)
./cluster.sh status    # Show cluster status and health
```

---

## Terraform Files

| File | Description |
|------|-------------|
| `main.tf` | AWS provider configuration |
| `variables.tf` | Input variables |
| `networking.tf` | VPC, subnets, security groups |
| `web_servers.tf` | EC2 instances with nginx |
| `load_balancer.tf` | ALB, target group, listener |
| `outputs.tf` | Output values |

---

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `web_server_count` | `2` | Number of web servers |
| `web_server_version` | `1.0.0` | Version of web servers |
| `load_balancer_version` | `1.0.0` | Version of load balancer |

Override at runtime:
```bash
TF_VAR_web_server_count=3 ./cluster.sh start
TF_VAR_web_server_version=2.0.0 ./cluster.sh start
```

---

## Endpoints

| Path | Returns |
|------|---------|
| `/` | `Hello from web-server-N` |
| `/health` | JSON with component name and version |

---

## Load Balancing Algorithms

| Algorithm | Description |
|-----------|-------------|
| **round_robin** ✅ | Requests distributed evenly in rotation |
| least_outstanding_requests | Routes to instance with fewest in-flight requests |
| weighted_random | Random selection weighted per target |

---

## Cost Estimate

| Resource | Cost |
|----------|------|
| 2x EC2 t3.micro | ~$0.02/hr |
| 1x ALB | ~$0.008/hr |
| **Total** | **~$0.03/hr** |

> Always run `./cluster.sh stop` when not in use!
אחרי שיצרת את הקובץ תרוץ:

bash
git add README.md
git commit -m "Step 6: Add README"
git push origin test
תדביק את הפלט ואז נעבור ל־BONUS — cluster שני. מוכן?


