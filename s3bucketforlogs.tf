module "s3_bucket_for_logs" {
  source = "./s3bucket-module"
  s3_bucket_name="${var.s3_bucket_name}"
  s3_aws_region="${var.AWS_REGION}"
}
