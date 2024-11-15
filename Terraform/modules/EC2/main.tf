##################################################
### SSH KEY ###
##################################################
# Read the public key from the specified path
# //NOT USING THIS FOR NOW BUT LEAVING JUST IN CASE
# locals {
#   public_key = file(var.public_key_path)
# }

# Generate a new SSH key pair
resource "tls_private_key" "generated_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.generated_key.public_key_openssh
# public_key = local.public_key  # Path to your public key file //LEAVING THIS IN CASE
}

# Saving private key as local tmp file on Jenkins server.
resource "local_file" "save_private_key" {
  content  = tls_private_key.generated_key.private_key_pem
  filename = "/tmp/terraform_generated_key.pem" # Temporary file
}

##################################################
### BASTION ###
##################################################
# Create an EC2 instance in AWS. This resource block defines the configuration of the instance.
# This EC2 is created in our Public Subnet
# Bastion AZ1
resource "aws_instance" "bastion1" {
  ami               = var.ami                          # The Amazon Machine Image (AMI) ID used to launch the EC2 instance.
  instance_type     = var.instance_type                # Specify the desired EC2 instance size.
  subnet_id         = var.public_subnet_1_id
  # Attach an existing security group to the instance.
  # Security groups control the inbound and outbound traffic to your EC2 instance.
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]         # Replace with the security group ID, e.g., "sg-01297adb7229b5f08".
  key_name          = var.key_name                # The key pair name for SSH access to the instance.
  

  # Tagging the resource with a Name label. Tags help in identifying and organizing resources in AWS.
  tags = {
    "Name" : "ecommerce_bastion_az1"
  }
}

# Bastion AZ2
resource "aws_instance" "bastion2" {
  ami               = var.ami                          # The Amazon Machine Image (AMI) ID used to launch the EC2 instance.
  instance_type     = var.instance_type                # Specify the desired EC2 instance size.
  subnet_id         = var.public_subnet_2_id
  # Attach an existing security group to the instance.
  # Security groups control the inbound and outbound traffic to your EC2 instance.
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]         # Replace with the security group ID, e.g., "sg-01297adb7229b5f08".
  key_name          = var.key_name                # The key pair name for SSH access to the instance.
  

  # Tagging the resource with a Name label. Tags help in identifying and organizing resources in AWS.
  tags = {
    "Name" : "ecommerce_bastion_az2"
  }
}

# Create a security group named "tf_made_sg" that allows SSH and HTTP traffic.
# This security group will be associated with the EC2 instance created above.
# This is Security Group for Jenkins
resource "aws_security_group" "bastion_sg" { # aws_security_group is the actual AWS resource name. web_ssh is the name stored by Terraform locally for record keeping 
  vpc_id      = var.wl6vpc_id
  name        = "Bastion SG"
  description = "Security group for Bastion EC2 instances."
  # Ingress rules: Define inbound traffic that is allowed.Allow SSH traffic and HTTP traffic on port 8080 from any IP address (use with caution)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Egress rules: Define outbound traffic that is allowed. The below configuration allows all outbound traffic from the instance.
  egress {
    from_port   = 0                                     # Allow all outbound traffic (from port 0 to any port)
    to_port     = 0
    protocol    = "-1"                                  # "-1" means all protocols
    cidr_blocks = ["0.0.0.0/0"]                         # Allow traffic to any IP address
  }
  # Tags for the security group
  tags = {
    "Name"      : "Bastion SG"                          # Name tag for the security group
    "Terraform" : "true"                                # Custom tag to indicate this SG was created with Terraform
  }
}

##################################################
### APP ###
##################################################
# Create an EC2 instance in AWS. This resource block defines the configuration of the instance.
# This EC2 is created in our Public Subnet
# App AZ1
resource "aws_instance" "app1" {
  ami               = var.ami                          # The Amazon Machine Image (AMI) ID used to launch the EC2 instance.
  instance_type     = var.instance_type                # Specify the desired EC2 instance size.
  subnet_id         = var.private_subnet_1_id
  # Attach an existing security group to the instance.
  # Security groups control the inbound and outbound traffic to your EC2 instance.
  vpc_security_group_ids = [aws_security_group.app_sg.id]         # Replace with the security group ID, e.g., "sg-01297adb7229b5f08".
  key_name          = var.key_name                # The key pair name for SSH access to the instance.
  user_data         = base64encode(templatefile("./scripts/deploy.sh", {
    rds_endpoint = var.rds_endpoint,
    dockerhub_username = var.dockerhub_username,
    dockerhub_password = var.dockerhub_password,
    docker_compose = templatefile("./compose.yml", {
      rds_endpoint = var.rds_endpoint
    })
  }))

  # Depends on RDS Instance to be created.
  depends_on = [
    var.rds_db,
    var.nat_gateway_1
  ]
  # Tagging the resource with a Name label. Tags help in identifying and organizing resources in AWS.
  tags = {
    "Name" : "ecommerce_app_az1"
  }
}

# App AZ2
resource "aws_instance" "app2" {
  ami               = var.ami                          # The Amazon Machine Image (AMI) ID used to launch the EC2 instance.
  instance_type     = var.instance_type                # Specify the desired EC2 instance size.
  subnet_id         = var.private_subnet_2_id
  # Attach an existing security group to the instance.
  # Security groups control the inbound and outbound traffic to your EC2 instance.
  vpc_security_group_ids = [aws_security_group.app_sg.id]         # Replace with the security group ID, e.g., "sg-01297adb7229b5f08".
  key_name          = var.key_name                # The key pair name for SSH access to the instance.
  user_data         = base64encode(templatefile("./scripts/deploy.sh", {
    rds_endpoint = var.rds_endpoint,
    docker_user = var.dockerhub_username,
    docker_pass = var.dockerhub_password,
    docker_compose = templatefile("./compose.yml", {
      rds_endpoint = var.rds_endpoint
    })
  }))
  
  # Depends on RDS Instance to be created.
  depends_on = [
    var.rds_db,
    var.nat_gateway_2
  ]

  # Tagging the resource with a Name label. Tags help in identifying and organizing resources in AWS.
  tags = {
    "Name" : "ecommerce_app_az2"
  }
}

# Create a security group named "tf_made_sg" that allows SSH and HTTP traffic.
# This security group will be associated with the EC2 instance created above.
# This is Security Group for Jenkins
resource "aws_security_group" "app_sg" { # aws_security_group is the actual AWS resource name. web_ssh is the name stored by Terraform locally for record keeping 
  vpc_id      = var.wl6vpc_id
  name        = "App SG"
  description = "Security group for App EC2 instances"
  # Ingress rules: Define inbound traffic that is allowed.Allow SSH traffic and HTTP traffic on port 8080 from any IP address (use with caution)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/20"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/20"]
  }
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Egress rules: Define outbound traffic that is allowed. The below configuration allows all outbound traffic from the instance.
  egress {
    from_port   = 0                                     # Allow all outbound traffic (from port 0 to any port)
    to_port     = 0
    protocol    = "-1"                                  # "-1" means all protocols
    cidr_blocks = ["0.0.0.0/0"]                         # Allow traffic to any IP address
  }
  # Tags for the security group
  tags = {
    "Name"      : "App SG"                              # Name tag for the security group
    "Terraform" : "true"                                # Custom tag to indicate this SG was created with Terraform
  }
}