resource "aws_iam_role" "firehose_role" {
  name = "firehose_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "firehose_role_policy" {
  role = "${aws_iam_role.firehose_role.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":
    [
        {
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::${var.s3_bucket_name}",
                "arn:aws:s3:::${var.s3_bucket_name}/*"
            ]
        },
        {
           "Effect": "Allow",
           "Action": [
               "kms:Decrypt",
               "kms:GenerateDataKey"
           ],
           "Resource": [
               "arn:aws:kms:${var.AWS_REGION}:${var.AWS_ACCOUNT}:key/${var.AWS_KMS_KEY_ID}"
           ],
           "Condition": {
               "StringEquals": {
                   "kms:ViaService": "s3.${var.AWS_REGION}.amazonaws.com"
               },
               "StringLike": {
                   "kms:EncryptionContext:aws:s3:arn": "arn:aws:s3:::${var.s3_bucket_name}/${var.AWS_KMS_PREFIX}*"
               }
           }
        },
        {
           "Effect": "Allow",
           "Action": [
               "logs:PutLogEvents"
           ],
           "Resource": [
               "arn:aws:logs:${var.AWS_REGION}:${var.AWS_ACCOUNT}:log-group:${var.AWS_LOG_GROUP_NAME}:log-stream:${var.AWS_LOG_STREAM_NAME}"
           ]
        },
        {
           "Effect": "Allow",
           "Action": [
               "lambda:InvokeFunction",
               "lambda:GetFunctionConfiguration"
           ],
           "Resource": [
               "arn:aws:lambda:${var.AWS_REGION}:${var.AWS_ACCOUNT}:function:${var.AWS_FUNCTION_NAME}:${var.AWS_FUNCTION_VERSION}"
           ]
        }
    ]
}
EOF
}

resource "aws_kinesis_firehose_delivery_stream" "cloudwatch_logs_stream" {
  name        = "cloudwatch_logs_stream"
  destination = "s3"

  s3_configuration {
    role_arn   = "${aws_iam_role.firehose_role.arn}"
    bucket_arn = "${module.s3_bucket_for_logs.bucket_arn}"
compression_format="ZIP"
 }
depends_on = ["aws_iam_role_policy.firehose_role_policy"]
}


resource "aws_iam_role" "cloudwatch_logs" {
  name = "cloudwatch_logs"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "logs.us-west-2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "cloudwatch_logs_policy" {
  role = "${aws_iam_role.cloudwatch_logs.name}"
  policy = <<EOF
{
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["firehose:*"],
      "Resource": ["${aws_kinesis_firehose_delivery_stream.cloudwatch_logs_stream.arn}"]
    }
  ]
}
EOF
}
resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_log_filter" {
  name            = "cloudwatch_log_filter"
  role_arn        = "${aws_iam_role.cloudwatch_logs.arn}"
  log_group_name  = "${var.AWS_LOG_GROUP_NAME_CLOUDWATCH}"
  filter_pattern  = ""
  destination_arn = "${aws_kinesis_firehose_delivery_stream.cloudwatch_logs_stream.arn}"
  depends_on = ["aws_iam_role_policy.cloudwatch_logs_policy","aws_instance.winrm"]
}
