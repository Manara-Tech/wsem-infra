output "artifacts_bucket_name" {
  value       = aws_s3_bucket.artifacts.bucket
  description = "Shared S3 bucket for application artifacts"
}
