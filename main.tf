terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region     = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

# Create source S3 bucket
resource "aws_s3_bucket" "source_bucket" {
  bucket = var.source_bucket_name
  force_destroy = true
  provisioner "local-exec" {
    when    = destroy
    command = "aws s3 rm s3://${self.id} --recursive"
  }
}

# Create destination S3 bucket
resource "aws_s3_bucket" "destination_bucket" {
  bucket = var.destination_bucket_name
  force_destroy = true
    provisioner "local-exec" {
    when    = destroy
    command = "aws s3 rm s3://${self.id} --recursive"
  }
}

# Upload file to source bucket
resource "aws_s3_object" "source_file" {
  bucket = aws_s3_bucket.source_bucket.id
  key    = var.file_name
  source = var.local_file_path

  # Verify upload was successful
  lifecycle {
    postcondition {
      condition     = self.etag != ""
      error_message = "Failed to upload file to source bucket"
    }
  }
}

# Create zip file for Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda function to process the file
resource "aws_lambda_function" "process_file" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "process_file"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SOURCE_BUCKET      = var.source_bucket_name
      DESTINATION_BUCKET = var.destination_bucket_name
    }
  }

  # Print zip contents for debugging
  provisioner "local-exec" {
    command = "unzip -l ${data.archive_file.lambda_zip.output_path}"
  }
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda function
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.source_bucket.arn,
          "${aws_s3_bucket.source_bucket.arn}/*",
          aws_s3_bucket.destination_bucket.arn,
          "${aws_s3_bucket.destination_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# S3 bucket notification to trigger Lambda
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.source_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_file.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

# Lambda permission to allow S3 to invoke the function
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_file.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source_bucket.arn
}

# Invoke Lambda function
resource "aws_lambda_invocation" "process_file_invocation" {
  function_name = aws_lambda_function.process_file.function_name
  input = jsonencode({
    Records = [{
      s3 = {
        bucket = {
          name = aws_s3_bucket.source_bucket.id
        }
        object = {
          key = aws_s3_object.source_file.key
        }
      }
    }]
  })

  depends_on = [aws_s3_object.source_file, aws_lambda_function.process_file]
}

# Outputs
output "source_file_location" {
  value       = "s3://${aws_s3_bucket.source_bucket.id}/${aws_s3_object.source_file.key}"
  description = "S3 location of the source file"
}

output "destination_file_location" {
  value       = "s3://${aws_s3_bucket.destination_bucket.id}/${var.file_name}-formatted"
  description = "S3 location of the processed file"
}

# Verify file exists in both buckets
data "aws_s3_object" "source_file_check" {
  bucket = aws_s3_bucket.source_bucket.id
  key    = var.file_name

  depends_on = [aws_s3_object.source_file]
}

data "aws_s3_object" "destination_file_check" {
  bucket = aws_s3_bucket.destination_bucket.id
  key    = "${var.file_name}-formatted"

  depends_on = [aws_lambda_invocation.process_file_invocation]
}

output "verification" {
  value = "File exists in both buckets: ${data.aws_s3_object.source_file_check.last_modified != "" && data.aws_s3_object.destination_file_check.last_modified != ""}"
}