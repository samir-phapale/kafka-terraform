# Kafka on EC2 (Terraform)

Single-node Apache Kafka (KRaft mode, no ZooKeeper) on an EC2 instance,
provisioned with Terraform and deployed via GitHub Actions.

## What this creates

- VPC with public + private subnets across 2 AZs
- Security group with no public inbound access (SSM only, no SSH, no open Kafka port)
- IAM role for the instance (SSM-managed, least privilege)
- EC2 instance running Kafka 4.1 in KRaft mode, with a topic created on boot

## Prerequisites

- AWS credentials configured (`aws configure` or SSO)
- Terraform >= 1.11
- An S3 bucket for Terraform state

## One-time setup: create the state bucket

```bash
aws s3api create-bucket --bucket <your-bucket-name> --region us-east-1
aws s3api put-bucket-versioning --bucket <your-bucket-name> --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket <your-bucket-name> \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

## Deploy locally

```bash
cp backend.hcl.example backend.hcl   # edit with your bucket name
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

## Test it

```bash
pip install -r tests/requirements.txt
export AWS_REGION=us-east-1
export KAFKA_INSTANCE_ID=$(terraform output -raw instance_id)
export KAFKA_TOPIC_NAME=$(terraform output -raw kafka_topic_name)
pytest tests/test_kafka_e2e.py -v -s
```

## Connect to the broker

```bash
aws ssm start-session --target $(terraform output -raw instance_id)
```

## Destroy

```bash
terraform destroy
```

## CI/CD

Three GitHub Actions workflows. Requires the repo secret `AWS_ROLE_ARN` and
variables `AWS_REGION` / `TF_STATE_BUCKET` to be set.

| Workflow | Trigger | What it does |
|---|---|---|
| `terraform-plan.yml` | Pull request | `fmt`, `validate`, `plan` — read-only |
| `terraform-apply.yml` | Push to `main` | apply, run tests, auto-destroy if everything passes |
| `terraform-destroy.yml` | Manual only | type `destroy-dev` to confirm |

## Security notes

- No SSH, no public Kafka port — all access goes through AWS Systems Manager
- IMDSv2 enforced, EBS volume encrypted
- IAM role on the instance grants only SSM access
