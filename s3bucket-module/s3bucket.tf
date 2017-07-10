resource "aws_s3_bucket" "tsys_bucket" {
  bucket= "${var.s3_bucket_name}"
  acl="${var.s3_bucket_acl}"
  versioning = {
    enabled="${var.versioning}"
  }
  tags ={
    owner ="blue Team"
  }
}

output "bucket_id" {
  value="${aws_s3_bucket.tsys_bucket.id}"
}

output "bucket_arn" {
  value="${aws_s3_bucket.tsys_bucket.arn}"
}
