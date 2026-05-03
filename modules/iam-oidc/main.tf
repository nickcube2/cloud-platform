# ── GitHub OIDC Provider ──────────────────────────────────────────
# One provider per AWS account. If it already exists, set
# create_oidc_provider = false to use a data source instead.

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = local.tags
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? (
    aws_iam_openid_connect_provider.github[0].arn
  ) : data.aws_iam_openid_connect_provider.github[0].arn

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

# ── Plan Role — read only, any branch can assume ──────────────────
resource "aws_iam_role" "plan" {
  name               = "${var.project}-github-plan-role"
  assume_role_policy = data.aws_iam_policy_document.plan_assume.json

  tags = merge(local.tags, { Purpose = "terraform-plan" })
}

data "aws_iam_policy_document" "plan_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ── Apply Role — scoped write, main branch only ───────────────────
resource "aws_iam_role" "apply" {
  name               = "${var.project}-github-apply-role"
  assume_role_policy = data.aws_iam_policy_document.apply_assume.json

  tags = merge(local.tags, { Purpose = "terraform-apply" })
}

data "aws_iam_policy_document" "apply_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role_policy" "apply" {
  name   = "${var.project}-apply-policy"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.apply_permissions.json
}

data "aws_iam_policy_document" "apply_permissions" {
  statement {
    sid       = "VPCManagement"
    actions   = ["ec2:*"]
    resources = ["*"]
  }

  statement {
    sid       = "ECSManagement"
    actions   = ["ecs:*", "elasticloadbalancing:*"]
    resources = ["*"]
  }

  statement {
    sid = "IAMScoped"
    actions = [
      "iam:CreateRole", "iam:DeleteRole",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy",
      "iam:PutRolePolicy", "iam:DeleteRolePolicy",
      "iam:GetRole", "iam:GetRolePolicy",
      "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
      "iam:PassRole", "iam:TagRole", "iam:UntagRole",
      "iam:CreateOpenIDConnectProvider",
      "iam:GetOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "CloudWatchLogs"
    actions   = ["logs:*"]
    resources = ["*"]
  }

  statement {
    sid = "StateAccess"
    actions = [
      "s3:GetObject", "s3:PutObject",
      "s3:DeleteObject", "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.project}-*",
      "arn:aws:s3:::${var.project}-*/*"
    ]
  }

  statement {
    sid = "DynamoDBLock"
    actions = [
      "dynamodb:GetItem", "dynamodb:PutItem",
      "dynamodb:DeleteItem", "dynamodb:DescribeTable"
    ]
    resources = ["arn:aws:dynamodb:*:*:table/${var.project}-*"]
  }

  statement {
    sid     = "KMS"
    actions = ["kms:GenerateDataKey", "kms:Decrypt", "kms:DescribeKey"]
    resources = ["*"]
  }
}