variable "project" { default = "roboshop" }
variable "env"     { default = "dev" }
variable "region"  { default = "us-east-1"}

variable "remote_state_s3_bucket"     { default = "roboshop-dev-tfstate-123" }
variable "remote_state_s3_bucket_key" { default = "roboshop-vpc-eks/terraform.tfstate" }

variable "namespace"       { default = "roboshop-dev" }
variable "service_account" { default = "cart-sa" }
variable "dynamodb_table"  { default = "roboshop-cart" }
