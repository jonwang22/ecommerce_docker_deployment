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

For our Jenkins server, we'll be using a t3.micro instance. We'll only need Jenkins on this EC2 so we'll only need to install Jenkins and all the software dependencies for Jenkins like Java 17.

The script I used to install Jenkins can be [found here](https://github.com/jonwang22/ecommerce_docker_deployment/blob/main/Scripts/install_jenkins.sh).

#### <ins>Docker & Terraform (DT) Setup</ins>

For our Docker_Terraform(DT) instance, we're using a t3.medium since we'll be building images with docker and using terraform to create our infrastructure in our AWS account. We need to install Java17, Terraform, Docker, and AWS CLI (This can be optional). 

The script I used to install all the tools mentioned before can be [found here](https://github.com/jonwang22/ecommerce_docker_deployment/blob/main/Scripts/install_docker_terraform.sh).

Now, if we want Terraform to know which AWS account to build the infrastructure on, we'll need to configure AWS Profile via AWS CLI with our Secret Key and Secret Access Key. However, there's another method to circumvent the need for AWS CLI. This leads us to IAM Roles. We need to create an IAM Role for our Docker_Terraform instance to assume and then be able to build our Infrastructure. I created an IAM Role for the EC2 service, which created an EC2 Instance Profile. This Instance Profile is then attached to the Docker_Terraform instance and here is the policy for the IAM Role.

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
                    "ec2:InstanceProfile": "arn:aws:iam::$AWS_ACCOUNT:instance-profile/TerraformEC2Role"
                }
            }
        }
    ]
}
```

#### <ins>Jenkins Build-Node Setup</ins>
Now that we have our Jenkins server and Docker_Terraform server, we'll need to setup our Docker_Terraform The next few steps will guide you on how to set up a Jenkins Node Agent. 

There are a few reasons why DT is being used as a build-node.

* Security on our pipeline, only those who have permissions to build the pipeline will have permissions to build and deploy the pipeline. Especially if our Jenkins server is being used by multiple teams.
* t3.medium is for handling the compute necessary for the build and also Terraform apply. Bigger instance allows for more resources for the build-node.

To set up the build-node on to Jenkins, we need to make sure both instances are running and then log into the Jenkins console in the Jenkins Manager instance.  On the left side of the home page under the navigation panel and "Build Queue", Click on "Build Executor Status", Click on "New Node", Name the node "build-node" and select "Permanent Agent".

On the next screen,
  
      i. "Name" should read "build-node"

      ii. "Remote root directory" == "/home/ubuntu/agent"

      iii. "Labels" == "build-node"

      iv. "Usage" == "Only build jobs with label expressions matching this node"

      v. "Launch method" == "Launch agents via SSH"

      vi. "Host" is the Private IP address of the Node Server

      vii. Click on "+ ADD" under "Credentials" and select "Jenkins".

      viii. Under "Kind", select "SSH Username with private key"

      ix. "ID" == "build-node"

      x. "Username" == "ubuntu"

      xi. "Private Key" == "Enter directly" (paste the entire private key of the Jenkins node instance here. This must be the .pem file)

      xi. Click "Add" and then select the credentials you just created.  

      xii. "Host Key Verification Strategy" == "Non verifying Verification Strategy"

      xiii. Click on "Save"

Back on the Dashboard, you should see "build-node" under "Build Executor Status".  Click on it and then view the logs.  If this was successful it will say that the node is "connected and online".

#### <ins>Monitoring</ins>

To monitor our environment, we need a monitoring server. We'll use a t3.micro and install Prometheus and Grafana. The script to install the services can be [found here](https://github.com/jonwang22/ecommerce_docker_deployment/blob/main/Scripts/install_prometheus_grafana.sh). We will be installing Node Exporter on both our app instances and use those as our Prometheus targets to pull metrics from. Grafana will be set up to display the data on a dashboard.

In order to set up Prometheus to target Node Exporter on the various instances, we need to configure the Prometheus.yml file.
Since we have VPC Peering, we can use the Private IPs of the production instances. 

The code block we need to modify looks like this.
```
/opt/prometheus/prometheus.yml

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100'] # <----CHANGE 'localhost' to private IP of target instance
```

### <ins>Infrastructure as Code - Terraform</ins>

For the infrastructure, I wrote modules to break out my code. I have VPC, EC2, RDS, and ALB modules. Below sections are for each module and has a list of each component created within the modules. If needed please refer to the main.tfs in each module for more information.

#### <ins>VPC Module</ins>

Contains:
```
- 1x Custom VPC
- 2x Public Subnets
- 2x Private Subnets
- 1x Internet Gateway
- 2x Elastic IPs
- 2x NAT Gateways
- 1x Public Route Table and associations to 2x Public Subnets
- 2x Private Route Tables and associations to respective Private Subnets
- 1x VPC Peering Connection
```

#### <ins>EC2 Module</ins>

Contains:
```
- 1x Terraform Generated SSH Key to use for EC2s
- 2x Bastion Servers
- 1x Bastion Security Group
- 2x App Servers
- 1x App Security Group
```

#### <ins>RDS Module</ins>

Contains:
```
- 1x Postgres Instance
- 1x DB Subnet Group
- 1x RDS Security Group
```

#### <ins>ALB Module</ins>

Contains:
```
- 1x Application Load Balancer
- 1x ALB Security Group
- 1x Listener
- 1x Target Group
- 2x Target Group Attachments
```

### <ins>Terraform EC2 User Data and Deploy Script</ins>

For our EC2 User_Data, we will be running our `deploy.sh` script. You can find the [deploy.sh script here](https://github.com/jonwang22/ecommerce_docker_deployment/blob/main/Terraform/scripts/deploy.sh). This script will install node exporter to track server metrics, install docker, create our docker-compose.yml file from our compose.yml file, run docker compose pull to pull the images from Docker Hub, and then run docker compose up to spin up our containers.

With our compose file, we need to make sure that we can build the images we pull from Docker Hub. Instead of having a script within the compose file, I created a separate script that will run my DB migrations on a single instance with a unique flag for running migrations. This flag is set on each App EC2 under user_data for creating docker-compose.yml. The backend script can be [found here](https://github.com/jonwang22/ecommerce_docker_deployment/blob/main/backend/django_start.sh). Our compose file is now lightweight and only contains the necessary information for docker compose to run the services.

### <ins>Docker</ins>

For Docker, we need to create our Docker Compose file on our Terraform created EC2 instances. In order to do this, we're leveraging a compose.yml template file, along with EC2 User_Data. As Terraform builds our infrastructure and begins building our App EC2 instances, our `deploy.sh` script will handle all the installations necessary for Docker and this is where the `docker-compose.yml` file gets created. Once created, Docker will then run a `docker compose pull` to pull the images built by Jenkins from our Docker Hub, then run a `docker compose up` to spin up those containers automatically. 

We'll also need to create our Dockerfiles for both Frontend and Backend to be able to build our images via Jenkins pipeline. You can find the files here. [Frontend](https://github.com/jonwang22/ecommerce_docker_deployment/blob/main/Dockerfile.frontend) and [Backend](https://github.com/jonwang22/ecommerce_docker_deployment/blob/main/Dockerfile.backend).

### <ins>Jenkins Pipeline</ins>

The Jenkins pipeline will contain the following stages. 

#### <ins>Build</ins>

The "Build" stage is making sure we have the correct version dependencies and we have the proper version of python for our application.

#### <ins>Test</ins>

The "Test" stage is testing our unit tests that we have written for our backend. We need to make sure that we set our default database to the SQLite database and not the RDS Postgres DB because it doesn't exist yet. I ended up creating a separate Settings.py file called `settings-test.py` and setting the default db to SQLite. 

#### <ins>Cleanup</ins>

The "Cleanup" stage is cleaning the build-node by pruning Docker system and performing a git clean preserving the tfstate file and .terraform directory. This ensures that we refresh the source code in our build-node's workspace and we're updating our environments as we go but maintain the infrastructure with the tfstate file.

#### <ins>Build & Push Image</ins>

The "Build & Push Image" stage is going to build our Dockerfiles for Frontend and Backend into images and push these images into Docker Hub. We do this so that we will always have up to date images depending on whatever source code updates we have or make to our repository.

#### <ins>Infrastructure</ins>

The "Infrastructure" stage will perform all our Terraform actions and build out our infrastructure. This is where all the magic automation happens and if everything is configured properly and written properly then our application will be deployed and we can access our app.

#### <ins>Post</ins>

The "Post" step at the end of the pipeline has an Always flag and will always run after the pipeline regardless of the status of the pipeline (Success vs Failure). This post step needs to run to clean up our build-node instance by logging out of Docker and performing a Docker system prune. 

## SYSTEM DESIGN
![Workload6](https://github.com/user-attachments/assets/4c48d72e-2325-452b-af3c-eb0487ca8651)

## ISSUES/TROUBLESHOOTING
* Creating script within compose.yml and pushing that into user_data to create the docker-compose.yml file needed to create the containers we need for our app. I was not able to figure out how to write the script correctly in order for it to be inserted into another script that will create the docker-compose.yml. To circumvent this, I had to create a completely separate script within the backend directory and reference that script to execute within the backend dockerfile.

* Test stage defaults to RDS PG instance and not SQLite DB. In order to successfully run test commands and pytests, need to set default to SQLite DB but then also make sure that during our deployment, we reference the RDS DB for the container when we run manage.py on the container.

## OPTIMIZATION

1. Separate Frontend and Backend into their own instances rather than living on the same instance to create some separation. It might not be necessary since the App server is private already.

2. Put the RDS DB into its own subnet.

3. Figure out how to make the compose.yml script transfer and create into a docker-compose.yml without using a separate script to run on the backend dockerfile.

## CONCLUSION

Great workload to learn about Docker and using containers in an application setting. Using Jenkins, Terraform, and Docker together in one single deployment has been really fun and cool.


