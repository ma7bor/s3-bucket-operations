variable "AWS_ACCESS_KEY" {
  description = "AWS access key"
  type        = string
  default     = "your access key"
}

variable "AWS_SECRET_KEY" {
  description = "AWS secret key"
  type        = string
  default     = "your secret key"
}

variable "AWS_REGION" {
  description = "AWS region"
  type        = string
  default     = "your region"
}

variable "local_file_path" {
  description = "Local path of the file to be uploaded"
  type        = string
  default     = "../marwanfile.txt"
}

variable "source_bucket_name" {
  description = "Name of the source S3 bucket"
  type        = string
  default     = "marwan-bucket-source"
}

variable "destination_bucket_name" {
  description = "Name of the destination S3 bucket"
  type        = string
  default     = "marwan-bucket-destination"
}

variable "file_name" {
  description = "Name of the file to be uploaded and copied"
  type        = string
  default     = "marwanfile.txt"
}

variable "file_name-formatted" {
  description = "Name of the file to be uploaded and copied"
  type        = string
  default     = "marwanfileformatted.txt"
}