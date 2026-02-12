variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "bootstrap"
}

variable "allowed_repos_branches" {
  description = "List of GitHub repositories and branches allowed to assume the IAM role"
  type = list(object({
    org    = string
    repo   = string
    branch = string
  }))
  default = [
    {
      org    = "Manara-Tech"
      repo   = "wsem-infra"
      branch = "main"
    },
    {
      org    = "Manara-Tech"
      repo   = "wsem-app"
      branch = "main"
    }
  ]
}
