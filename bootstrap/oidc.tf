# Since our Terraform code talks to AWS as a provider, we need to
# provide a way for this workflow to authenticate to that provider.
# To do this, we create an IAM OIDC Provider that trusts GitHub's
# OIDC tokens, allowing our GitHub Actions workflows to assume roles
# in our AWS account.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com" # This is GitHub's OIDC URL
  client_id_list = ["sts.amazonaws.com"]                         # This is the audience for AWS STS
  #This prevents token misuse- a token meant for a different service won't work here

  thumbprint_list = [
    data.tls_certificate.github.certificates[0].sha1_fingerprint
    # This fetches the thumbprint of GitHub's OIDC provider certificate
    # using the TLS data source defined below
    # AWS requires this even though modern TLS already provides certificate validation
  ]
}
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
  # This data source retrieves the TLS certificate for GitHub's OIDC provider
}

# Now, we can create IAM roles that GitHub Actions can assume.

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated" # This means we're trusting an external identity provider
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      # The repos and branches defined in var.allowed_repos_branches
      # will be able to assume this IAM role
      values = [
        for repo in var.allowed_repos_branches :
        "repo:${repo["org"]}/${repo["repo"]}:ref:refs/heads/${repo["branch"]}"
      ]
      # This condition restricts the role assumption to workflows
      # in the specified GitHub repository
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
      # This condition prevents token misuse.
    }
  }
}

resource "aws_iam_role" "github_actions_role" {
  name               = "github-actions-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

resource "aws_iam_role_policy_attachment" "github_actions_role_attach" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  # For demonstration purposes, we attach the AdministratorAccess policy.
  # In a production environment, you should create and attach a more
  # restrictive policy that only allows the necessary actions.
}
