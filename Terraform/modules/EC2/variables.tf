### VPC VARIABLES
variable wl6vpc_id {
    description     = "VPC ID from VPC Module"
}
variable public_subnet_1_id {}
variable public_subnet_2_id {}
variable private_subnet_1_id {}
variable private_subnet_2_id {}
variable nat_gateway_1 {}
variable nat_gateway_2 {}

### EC2 VARIABLES
variable instance_type {
    description     = "Default EC2 Instance to use."
    type            = string
    default         = "t3.micro"
} 

variable ami {
    default         = "ami-0866a3c8686eaeeba"
}

variable "key_name" {
  description = "The name of the key pair"
  type        = string
  default     = "ecommerce-tf"
}

# variable "public_key_path" {}

### RDS VARIABLES
variable rds_endpoint {}
# variable db_name {}
# variable db_username {}
# variable db_password {}

### DOCKER VARIABLES
variable dockerhub_username {}
variable dockerhub_password {}
