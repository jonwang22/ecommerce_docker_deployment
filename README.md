# E-Commerce Website Docker Deployment

## PURPOSE

In the previous workload, we used Jenkins and Terraform to deploy an ecommerce application. In this one, the requirements are similar but adding Docker in our deployment infrastructure. We're going to deploy our frontend and backend portions of our application to containers. We'll create a Jenkins CI/CD pipeline to build and push our images to Dockerhub, then initiate Terraform to build our infrastructure and run our user data scripts on our EC2 instances to setup and use docker compose to deploy our app onto containers.

We're going to modify our infrastructure a bit from the previous deployment and place our containers into our private EC2 instance and have our Application Load Balancer route traffic to the containers. Our public subnet will just contain bastion EC2s for us to SSH onto our private EC2 instances to check on our logs and troubleshoot any issues we may see during deployment.

The situation for this workload is this. A new E-Commerce company wants to deploy their application to AWS Cloud Infrastructure that is secure, available, and fault tolerant. They also want to utilize Infrastructure as Code as well as a CICD pipeline to be able to spin up or modify infrastructure as needed whenever an update is made to the application source code.

## STEPS

### <ins>Ops Environment Setup</ins>

First we need to clone the [github repo of the source code](https://github.com/kura-labs-org/C5-Deployment-Workload-6/tree/main) so we can customize it for our use. Below are the steps on how to do so.

1. Create new repo on github called "ecommerce_docker_deployment".
2. Run `git clone $SOURCE_REPO`
3. Navigate to the repo and then run the following commands.
```
git remote rename origin upstream           #Changing the current remote origin repo to be named upstream
git remote add origin $WORKING_REPO         #Adding new remote origin repo to be assigned to desired repo
git branch -M main                          #Forces the current branch to be renamed "main"
git push -u origin main                     #Sets the upstream to origin remote repo and tracks main branch
```
4. Now your new repo should contain all the files from the source repo.
5. Run `git clone $WORKING_REPO` to pull down the repo you just created and will work in.
6. Delete the `$SOURCE_REPO` locally since it is not needed anymore.

Now that we have our working repository, we'll need to create a "Jenkins" server, a "Docker_Terraform" server, and "Monitoring" server. The Jenkins server will use the Docker_Terraform server as a build_node for this deployment.

#### <ins>Jenkins Setup</ins>

For our Jenkins server, we'll be using a t3.micro instance. 

#### <ins>Docker & Terraform Setup</ins>

#### <ins>Monitoring</ins>

### <ins>Infrastructure as Code - Terraform</ins>

### <ins>Terraform EC2 User Data and Deploy Script</ins>

### <ins>Docker</ins>

### <ins>Jenkins Pipeline</ins>


## SYSTEM DESIGN
![Workload6](https://github.com/user-attachments/assets/4c48d72e-2325-452b-af3c-eb0487ca8651)

## ISSUES/TROUBLESHOOTING
* Creating script within compose.yml and pushing that into user_data to create the docker-compose.yml file needed to create the containers we need for our app. I was not able to figure out how to write the script correctly in order for it to be inserted into another script that will create the docker-compose.yml. To circumvent this, I had to create a completely separate script within the backend directory and reference that script to execute within the backend dockerfile.

## OPTIMIZATION

## CONCLUSION

1. Clone this repo to your GitHub account and call it "ecommerce_docker_deployment".

2. Create a t3.micro EC2 called "Jenkins". This will be your Jenkins Manager instance. Install Jenkins and Java 17 onto it.

3. Create a t3.medium EC2 called "Docker_Terraform". This will be your Jenkins NODE instance. Install Java 17, Terraform, Docker, and AWS CLI onti it.  For this workload it would be easiest to use the same .pem key for both of these instances to avoid confusion when trying to connect them.

NOTE: Getting around using IAM User long lived credentials for Secret and Secret Access keys, I created an IAM role for EC2 and an EC2 Instance Profile so that Terraform Server can assume that role and conduct its build/operations as needed on the account.
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "ec2:InstanceProfile": "arn:aws:iam::783764590292:instance-profile/TerraformEC2Role"
                }
            }
        }
    ]
}
```

   NOTE: Make sure you configure AWS CLI and that Terraform can create infrastructure using your credentials (Optional: Consider adding a verification in your pipeline stage to check for this to avoid errors).

5. The next few steps will guide you on how to set up a Jenkins Node Agent.

  a. Make sure both instances are running and then log into the Jenkins console in the Jenkins Manager instance.  On the left side of the home page under the navigation panel and "Build Queue", Click on "Build Executor Status"

  b. Click on "New Node"

  c. Name the node "build-node" and select "Permanent Agent"

  d. On the next screen,
  
      i. "Name" should read "build-node"

      ii. "Remote root directory" == "/home/ubuntu/agent"

      iii. "Labels" == "build-node"

      iv. "Usage" == "Only build jobs with label expressions matching this node"

      v. "Launch method" == "Launch agents via SSH"

      vi. "Host" is the public IP address of the Node Server

      vii. Click on "+ ADD" under "Credentials" and select "Jenkins".

      viii. Under "Kind", select "SSH Username with private key"

      ix. "ID" == "build-node"

      x. "Username" == "ubuntu"

      xi. "Private Key" == "Enter directly" (paste the entire private key of the Jenkins node instance here. This must be the .pem file)

      xi. Click "Add" and then select the credentials you just created.  

      xii. "Host Key Verification Strategy" == "Non verifying Verification Strategy"

      xiii. Click on "Save"

   e. Back on the Dashboard, you should see "build-node" under "Build Executor Status".  Click on it and then view the logs.  If this was successful it will say that the node is "connected and online".
    
5. Create terraform files that will create the following infrastructure:

```
- 1x Custom VPC in us-east-1
- 2x Availability zones in us-east-1a and us-east-1b
- A private and public subnet in EACH AZ
- An EC2 in each subnet (EC2s in the public subnets are for the bastion host, the EC2s in the private subnets are for the front AND backend containers of the application) Name the EC2's: "ecommerce_bastion_az1", "ecommerce_app_az1", "ecommerce_bastion_az2", "ecommerce_app_az2"
- A load balancer that will direct the inbound traffic to either of the public subnets.
- An RDS databse
```
NOTE 1: This list DOES NOT include ALL of the resource blocks required for this infrastructure.  It is up to you to figure out what other resources need to be included to make this work.

NOTE 2: Put your terraform files into your GitHub repo in the "Terraform" directory.

Use the following "user_data" code for your EC2 resource block:
```
user_data = base64encode(templatefile("${path.module}/deploy.sh", {
    rds_endpoint = aws_db_instance.main.endpoint,
    docker_user = var.dockerhub_username,
    docker_pass = var.dockerhub_password,
    docker_compose = templatefile("${path.module}/compose.yaml", {
      rds_endpoint = aws_db_instance.main.endpoint
    })
  }))
```
Also make sure that you also include the following for the EC2 resource block:
```
  depends_on = [
    aws_db_instance.main,
    aws_nat_gateway.main
  ]
```
NOTE: Notice what is required for this user data block.  (var.dockerhub_username, var.dockerhub_password, deploy.sh, compose.yaml, and aws_db_instance.main.endpoint) Make sure that you declare the required variables and place the deploy.sh (must create) and compose.yaml (provided) in the same directory as your main.tf (Terraform directory in GitHub).

6. Create a deploy.sh file that will run in "user_data".
  
  a. This script must (in this order):
  
  i. install docker and docker-compose;

  ii. log into DockerHub;

  iii. create the docker-compose.yaml with the following code:

      ```
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating app directory..."
    mkdir -p /app
    cd /app
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Created and moved to /app"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating docker-compose.yml..."
    cat > docker-compose.yml <<EOF
    ${docker_compose}
    EOF
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] docker-compose.yml created"
    
    ```
   Note: How is this code creating the docker_compose.yaml file? (Hint: Look at "user_data" and the "Jenkinsfile")

   iv. run `docker-compose pull`

   v. run `docker-compose up -d --force-recreate`

   vi. Clean the server by running a docker system prune and logging out of dockerhub.  

   Be sure to try to understand each of these commands as they are vital to the success of this workload.  

   NOTE: You are not limited to running only these commands in this script.  If you want to include anything else to set up the server you are more than welcome to.

7. Create Dockerfiles for the backend and frontend images

  a. Name the Dockerfile for the backend "Dockerfile.backend"

   i. Pull the python:3.9 base image

   ii. Copy the "backend" directory into the image

   iii. install `django-environ` and all other dependencies

   iv. Run `python manage.py makemigrations account`, `python manage.py makemigrations payments`, `python manage.py makemigrations product`

   v. Expose port 8000

   vi. Set the command `python manage.py runserver 0.0.0.0:8000` to run when the container is started

  b. Name the Dockerfile for the frontend "Dockerfile.frontend"

   i. Pull the node:14 base image

   ii. Copy the "frontend" directory into the image

   iii. Run `npm install`

   iv. Expose port 3000

   v. Set the command `npm start` to run when the container is started

  c. Save these files to the root directory of your GitHub Repository

8. Modify the Jenkinsfile as needed to accomodate your files.

9. Modify the compose.yml file as needed to accomodate your files (image tags).

10. Create a Multi-Branch pipeline called "workload_6" and run the pipeline to deploy the application!

11. Create a monitoring EC2 in the default VPC that will monitor the resources of the various servers.  (Hopefully you read through these instructions in it's entirety before you ran the pipeline so that you could configure the correct ports for node exporter.)

12. Document! All projects have documentation so that others can read and understand what was done and how it was done. Create a README.md file in your repository that describes:

	  a. The "PURPOSE" of the Workload,

  	b. The "STEPS" taken (and why each was necessary/important),
    
  	c. A "SYSTEM DESIGN DIAGRAM" that is created in draw.io (IMPORTANT: Save the diagram as "Diagram.jpg" and upload it to the root directory of the GitHub repo.),

	  d. "ISSUES/TROUBLESHOOTING" that may have occured,

  	e. An "OPTIMIZATION" section for how you think this workload/infrastructure/CICD pipeline, etc. can be optimized further.  

    f. A "CONCLUSION" statement as well as any other sections you feel like you want to include.

