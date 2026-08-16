#!/usr/bin/env bash
set -euo pipefail

# ─── Config ───────────────────────────────────────────────────────────────────
TERRAFORM_VERSION="1.7.5"
ALB_NAME="devops-exercise-alb"
AWS_REGION="us-east-1"

# ─── Colors ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

log()  { echo -e "${CYAN}[INFO]${RESET} $*"; }
ok()   { echo -e "${GREEN}[OK]${RESET} $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
fail() { echo -e "${RED}[ERROR]${RESET} $*"; exit 1; }

# ─── Usage ────────────────────────────────────────────────────────────────────
usage() {
  echo ""
  echo "Usage: $0 <command>"
  echo ""
  echo "Commands:"
  echo "  install   Install Terraform and AWS CLI"
  echo "  start     Deploy the cluster (terraform apply)"
  echo "  stop      Destroy the cluster (terraform destroy)"
  echo "  status    Show cluster status"
  echo ""
}

# ─── Install ──────────────────────────────────────────────────────────────────
cmd_install() {
  log "Installing dependencies..."

  # Install Terraform
  if command -v terraform &>/dev/null; then
    ok "Terraform already installed: $(terraform version -json | python3 -c 'import sys,json; print(json.load(sys.stdin)["terraform_version"])')"
  else
    log "Installing Terraform v$TERRAFORM_VERSION..."
    sudo apt-get update -y -qq
    sudo apt-get install -y -qq gnupg software-properties-common curl unzip

    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update -y -qq
    sudo apt-get install -y terraform
    ok "Terraform installed"
  fi

  # Install AWS CLI
  if command -v aws &>/dev/null; then
    ok "AWS CLI already installed: $(aws --version 2>&1 | head -1)"
  else
    log "Installing AWS CLI..."
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip -q /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install
    rm -rf /tmp/aws /tmp/awscliv2.zip
    ok "AWS CLI installed"
  fi

  # Verify AWS credentials
  if aws sts get-caller-identity &>/dev/null; then
    ok "AWS credentials valid"
  else
    fail "AWS credentials not configured. Run: aws configure"
  fi

  # Terraform init
  log "Initializing Terraform..."
  terraform init -upgrade
  ok "Installation complete! Run './cluster.sh start' to deploy."
}

# ─── Start ────────────────────────────────────────────────────────────────────
cmd_start() {
  log "Starting cluster..."

  # Verify AWS credentials
  aws sts get-caller-identity &>/dev/null || fail "AWS credentials not configured."

  terraform apply -auto-approve

  # Show ALB URL
  ALB_DNS=$(aws elbv2 describe-load-balancers \
    --names "$ALB_NAME" \
    --region "$AWS_REGION" \
    --query "LoadBalancers[0].DNSName" \
    --output text 2>/dev/null || echo "")

  if [[ -n "$ALB_DNS" ]]; then
    ok "Cluster is up!"
    echo ""
    echo -e "  URL:    ${GREEN}http://$ALB_DNS${RESET}"
    echo -e "  Health: ${GREEN}http://$ALB_DNS/health${RESET}"
  fi
}

# ─── Stop ─────────────────────────────────────────────────────────────────────
cmd_stop() {
  warn "This will DESTROY all cluster resources!"
  read -rp "Are you sure? (yes/no): " confirm
  [[ "$confirm" == "yes" ]] || { warn "Aborted."; exit 0; }

  log "Stopping cluster..."
  terraform destroy -auto-approve
  ok "Cluster destroyed."
}

# ─── Status ───────────────────────────────────────────────────────────────────
cmd_status() {
  log "Checking cluster status..."

  # Check AWS credentials
  aws sts get-caller-identity &>/dev/null || fail "AWS credentials not configured."

  # Get ALB DNS
  ALB_DNS=$(aws elbv2 describe-load-balancers \
    --names "$ALB_NAME" \
    --region "$AWS_REGION" \
    --query "LoadBalancers[0].DNSName" \
    --output text 2>/dev/null || echo "")

  if [[ -z "$ALB_DNS" || "$ALB_DNS" == "None" ]]; then
    warn "Cluster is not running."
    return
  fi

  ok "Load Balancer: http://$ALB_DNS"

  # Check health
  HEALTH=$(curl -sf --max-time 5 "http://$ALB_DNS/health" || echo "")
  if [[ -n "$HEALTH" ]]; then
    ok "Health: $HEALTH"
  else
    warn "Load balancer not reachable yet."
  fi

  # Show EC2 instances
  echo ""
  log "EC2 Instances:"
  aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --filters "Name=tag:Name,Values=web-server-*" "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value,ID:InstanceId,IP:PublicIpAddress,State:State.Name}" \
    --output table
}

# ─── Main ─────────────────────────────────────────────────────────────────────
case "${1:-help}" in
  install) cmd_install ;;
  start)   cmd_start   ;;
  stop)    cmd_stop    ;;
  status)  cmd_status  ;;
  *)       usage       ;;
esac
