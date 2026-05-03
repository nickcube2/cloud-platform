# cloud-platform

A production-grade AWS platform built with Terraform. Designed to demonstrate consulting-grade infrastructure — modular, documented, observable, and handoff-ready.

---

## Architecture

```
Internet
   │
   ▼
ALB (public subnets — us-east-1a, us-east-1b)
   │
   ▼
ECS Fargate Tasks (private subnets — us-east-1a, us-east-1b)
   │
   ▼
NAT Gateway → Internet (ECR pull, external APIs)

GitHub Actions → OIDC → IAM Roles (no static keys)
Terraform State → S3 (KMS encrypted, versioned) + DynamoDB (lock table)
```

---

## What this platform includes

- **Remote state backend** — S3 with KMS encryption, versioning, and TLS enforcement. DynamoDB for state locking. Bootstrapped separately to solve the chicken-and-egg problem.
- **VPC** — Public and private subnets across 2 Availability Zones. Single NAT Gateway (cost-aware, scalable to 2 for full HA). VPC Flow Logs to CloudWatch for network observability.
- **ECS Fargate** — Application Load Balancer in public subnets routing to Fargate tasks in private subnets. Security groups using identity-based referencing, not CIDR ranges. Container Insights enabled.
- **IAM OIDC** — GitHub Actions assumes AWS roles via OIDC federation. No static credentials stored anywhere. Separate plan role (read-only, any branch) and apply role (scoped write, main branch only).
- **CI/CD** — Three GitHub Actions workflows: plan on PR, apply on merge to main with approval gate, drift detection on daily cron.

---

## Module structure

| Module | Responsibility |
|--------|----------------|
| `bootstrap/` | S3 state bucket, DynamoDB lock table, KMS key — run once manually |
| `modules/vpc/` | VPC, subnets, NAT Gateway, IGW, route tables, Flow Logs |
| `modules/ecs-service/` | ALB, ECS Fargate cluster and service, security groups, IAM task role, CloudWatch logs |
| `modules/iam-oidc/` | GitHub Actions OIDC provider, plan role, apply role |
| `environments/prod/` | Root module — wires all modules together, remote state backend |

---

## Key design decisions

### Why a separate bootstrap directory?
Terraform cannot manage its own state backend — the backend must exist before Terraform runs. Bootstrap creates the S3 bucket, DynamoDB table, and KMS key using local state, then all subsequent infrastructure uses that backend for remote state. This solves the chicken-and-egg problem cleanly.

### Why OIDC instead of IAM access keys in CI?
Static access keys are long-lived credentials that require manual rotation and can be leaked via git history or CI logs. OIDC issues short-lived tokens scoped to the exact repo and branch triggering the workflow. The apply role is locked to refs/heads/main — PRs and feature branches can only plan, never apply.

### Why separate plan and apply roles?
Plan is read-heavy. Engineers can be given plan access to inspect proposed changes without write risk. Apply is gated to main branch only and requires a human approval via GitHub environment protection rules before the job runs.

### Why one NAT Gateway instead of two?
Single NAT Gateway reduces cost by ~50% during development. The nat_gateway_count variable accepts any value — set it to match AZ count for full HA. The trade-off: if AZ-1 goes down, private subnet egress in that AZ fails. For client production workloads with strict RTO requirements, always match NAT count to AZ count.

### Why map_public_ip_on_launch = false on public subnets?
Public IP assignment is an explicit decision at the resource level, not an automatic behavior of the subnet. This prevents accidental internet exposure of resources that shouldn't be reachable directly — all inbound traffic must go through the ALB.

### Why security group rules as separate resources?
The ALB security group references the ECS security group in its egress rule, and vice versa. Defining rules inline creates a circular dependency Terraform cannot resolve. Separate aws_security_group_rule resources allow both groups to be created empty first, then rules are added after both exist.

### Why ignore_changes on desired_count?
If autoscaling adjusts the task count at runtime, a subsequent terraform apply would reset it back to the Terraform value — potentially scaling down a service under load. ignore_changes hands ownership of desired_count to the autoscaler at runtime while Terraform manages everything else.

### Why target_type = ip on the ALB target group?
Fargate tasks don't have EC2 instance IDs — they only have private IP addresses assigned when the task starts. target_type = instance requires an instance ID and will fail with Fargate. target_type = ip routes directly to the task's private IP in the VPC subnet.

### Why bucket_key_enabled = true on S3 encryption?
By default, every S3 object encrypted with KMS makes an individual API call to KMS. At scale this creates cost and throttling issues. Bucket keys generate one data key per bucket and use it for multiple objects, reducing KMS API calls with no impact on security.

---

## CI/CD workflow

```
Developer opens PR
       ↓
terraform-plan.yml runs automatically
Plan output posted as PR comment
       ↓
Team reviews exact AWS changes before approving
       ↓
PR merged to main
       ↓
terraform-apply.yml triggers
Manual approval required (GitHub environment protection)
       ↓
terraform apply runs against saved plan binary
       ↓
drift-detection.yml runs daily at 8am UTC
Alerts if infrastructure diverges from Terraform state
```

---

## Deployment

### Prerequisites
- AWS CLI configured
- Terraform >= 1.6.0
- GitHub repo secrets: AWS_PLAN_ROLE_ARN, AWS_APPLY_ROLE_ARN

### Step 1 — Bootstrap (run once)

```bash
cd bootstrap/
terraform init
terraform apply
```

### Step 2 — Update backend config

Paste state_bucket_name and dynamodb_table_name outputs into environments/prod/backend.tf

### Step 3 — Deploy

```bash
cd environments/prod/
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 4 — Verify

```bash
terraform output app_url
curl $(terraform output -raw app_url)
```

---

## Cost (approximate, destroy nightly)

| Resource | Est. daily cost |
|----------|----------------|
| NAT Gateway | ~$0.36 |
| ALB | ~$0.22 |
| ECS Fargate (2x 0.25vCPU/0.5GB) | ~$0.12 |
| S3, DynamoDB, CloudWatch | ~$0.01 |
| **Total** | **~$0.71/day** |

Run terraform destroy when not in use. Bootstrap resources cost ~$1/month and should remain.

---

## Repository

github.com/nickcube2/cloud-platform
