variable "aws_region" {
  description = "The AWS region to create resources in"
  default     = "eu-central-1" # Update with your region
}

variable "key_name" {
  description = "The name of the key pair to use for SSH access"
  default    = "new-key" # Update with your key pair name
}