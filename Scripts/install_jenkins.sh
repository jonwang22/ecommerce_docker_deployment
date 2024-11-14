#!/bin/bash

# Installing dependencies for Jenkins
sudo apt update

# Installing fontconfig and JavaDevKit for Jenkins.
sudo apt install -y fontconfig openjdk-17-jre software-properties-common

# Downloaded the Jenkins respository key. Added the key to the /usr/share/keyrings directory
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

# Added Jenkins repo to sources list
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Downloaded all updates for packages again, installed Jenkins
sudo apt-get update
sudo apt-get install jenkins -y

# Started Jenkins and checked to make sure Jenkins is active and running with no issues
sudo systemctl start jenkins
sudo systemctl status jenkins
