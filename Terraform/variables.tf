# AWS General Variables --- No longer needed due to IAM Role for EC2 and EC2 Instance Profile.
# variable aws_access_key{
#   type=string
#   sensitive=true
# }
# variable aws_secret_key{
#   type=string
#   sensitive=true
# }
variable region{
  default = "us-east-1"
}

# EC2 General Variables
# variable "public_key_path" {
#   description = "Path to the public key file"
#   type        = string
#   default     = "/home/ubuntu/.ssh/ecommerce.pub"  # You can also pass this as an environment variable
# }

# RDS Database Variables --- No longer needed for this workload
variable db_name {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = "ecommerce"
}

variable db_username {
  description = "Username for the master DB user"
  type        = string
  default     = "userdb"
}

variable db_password {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
}

### DOCKER VARIABLES
variable dockerhub_username {
  description = "Docker Hub Username"
  type        = string
  default     = "jonwang22"
}

variable dockerhub_password {
  description = "Docker Hub Password"
  type        = string
  sensitive   = true
}