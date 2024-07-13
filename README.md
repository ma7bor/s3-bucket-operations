# S3 File Processing with AWS Lambda

This project uses Terraform to set up an AWS infrastructure for automatic file processing. It creates two S3 buckets and a Lambda function. When a file is uploaded to the source bucket, it automatically triggers the Lambda function, which processes the file and places the result in the destination bucket.

The Lambda function performs the following operations on the uploaded file:
1. Reads the content of the file
2. Formats the text (e.g., removes extra whitespace, standardizes line breaks)
3. Converts the entire text to uppercase
4. Writes the processed content to a new file in the destination bucket

The upload process is fully automated. Once the infrastructure is set up, you only need to place a file in the source bucket, and the system will handle the rest - triggering the Lambda function, processing the file, and storing the result in the destination bucket without any manual intervention.


## Infrastructure Overview

The Terraform configuration creates the following AWS resources:

- Two S3 buckets: one for source files and one for processed files
- A Lambda function for file processing
- IAM roles and policies for the Lambda function
- S3 bucket notification to trigger the Lambda function

## Prerequisites

- AWS account
- Terraform installed on your local machine
- AWS CLI configured with your credentials

## Setup

1. Clone this repository:

    git clone [<repository-url>](https://github.com/ma7bor/s3-bucket-operations.git)
    cd configure-s3-buckets

2. Review and update the `variables.tf` file in the project root. This file contains declarations for variables used in the main configuration:
        variable "AWS_REGION" {
        default = "us-west-2"
        }

        variable "AWS_ACCESS_KEY" {}

        variable "AWS_SECRET_KEY" {}

        variable "source_bucket_name" {}

        variable "destination_bucket_name" {}

        variable "file_name" {}

        variable "local_file_path" {}


3- Initialize Terraform:
    terraform init

4- When you run Terraform commands, you'll be prompted to enter values for any variables that don't have default values. Alternatively, you can provide these values using command-line flags or environment variables.

5-Review the planned changes:
    terraform plan

## Usage
Once the infrastructure is set up:

    1-  Upload a file to the source S3 bucket.
    2- The Lambda function will automatically process the file and place the result in the destination bucket.
    3- Check the destination bucket for the processed file.

Lambda Function: 
The Lambda function (lambda_function.py) reads the file from the source bucket, processes it (in this example, it converts the text to uppercase), and writes the result to the destination bucket.

Cleaning Up
To destroy the created resources:
    terraform destroy

## Note
This is a basic example and may need to be adapted for production use. Always follow AWS best 
practices for security and cost management.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

License

MIT