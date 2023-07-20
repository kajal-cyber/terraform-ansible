pipeline {
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_credentials')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_credentials')
        PRI_KEY = credentials('AWS_privatekey')
    }
    agent any
  stages {
    stage('Provision Infrastructure') {
        steps {
            // credentialsId loading private key and storing in var
            withCredentials([sshUserPrivateKey(
                credentialsId: 'AWS_privatekey',
                keyFileVariable: 'SSH_KEY')])
            {
                sh 'cp "$SSH_KEY" /var/tmp/Demo_ans_key.pem'
            }
        }
    }

    stage('checkout') {
            steps {
                 script{
                        dir("terraform")
                        {
                            git branch: 'main', url: 'https://github.com/kajal-cyber/test.git'
                        }
                    }
                }
            }
        stage('Terraform init') {
            steps {
                 sh 'pwd;cd terraform/ ; terraform init'
            }
        }
       stage('Terraform plan') {
            steps {
                sh 'pwd;cd terraform/ ; terraform plan'
            }
        }
     
        stage('Terraform apply') {
            steps {
                sh 'pwd;cd terraform/ ; terraform apply --auto-approve'
            }
        }
      
        
    }
}


