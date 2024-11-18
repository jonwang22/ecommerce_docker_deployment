pipeline {
  agent any

  environment {
    DOCKER_CREDS = credentials('docker-hub-credentials')
    DB_PASSWORD = credentials('db_password')
  }

  stages {
    stage ('Build') {
      agent any
      steps {
        sh '''#!/bin/bash
        python3.9 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip
        pip install -r backend/requirements.txt
        '''
      }
    }

    stage ('Test') {
      agent any
      steps {
        sh '''#!/bin/bash
        source venv/bin/activate
        pip install pytest-django
        python backend/manage.py makemigrations
        python backend/manage.py migrate
        pytest backend/account/tests.py --verbose --junit-xml test-reports/results.xml
        ''' 
      }
    }

    stage('Cleanup') {
      agent { label 'build-node' }
      steps {
        sh '''
          # Only clean Docker system
          docker system prune -f
          
          # Safer git clean that preserves terraform state
          git clean -ffdx -e "*.tfstate*" -e ".terraform/*"
        '''
      }
    }

    stage('Build & Push Images') {
      agent { label 'build-node' }
      steps {
        sh 'echo ${DOCKER_CREDS_PSW} | docker login -u ${DOCKER_CREDS_USR} --password-stdin'
        
        // Build and push backend
        sh '''
          docker build -t jonwang22/ecommerce_backend:latest -f Dockerfile.backend .
          docker push jonwang22/ecommerce_backend:latest
        '''
        
        // Build and push frontend
        sh '''
          docker build -t jonwang22/ecommerce_frontend:latest -f Dockerfile.frontend .
          docker push jonwang22/ecommerce_frontend:latest
        '''
      }
    }

    stage('Infrastructure') {
      agent { label 'build-node' }
      steps {
        dir('Terraform') {
          sh '''
            terraform init
            terraform apply -auto-approve \
              -var="dockerhub_username=${DOCKER_CREDS_USR}" \
              -var="dockerhub_password=${DOCKER_CREDS_PSW}" \
              -var="db_password=${DB_PASSWORD}"
          '''
        }
      }
    }
  }

  post {
    always {
      node('build-node') {
        sh '''
          docker logout
          docker system prune -f
        '''
      }
    }
  }
}
