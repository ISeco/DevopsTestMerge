pipeline {
  agent any
  tools { 
    maven 'jenkins-maven' 
    jdk 'Java 11' 
  }
  environment {
    DOCKER_TAG = sh(script: 'echo $BUILD_NUMBER', returnStdout: true).trim()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout([
          $class: 'GitSCM', 
          branches: [[name: 'main']],
          userRemoteConfigs: [[url: 'git@github.com:ISeco/DevopsTestMerge.git']]
        ])
      }
    }
    stage('Clean Package') {
      steps {
        sh "mvn clean package"
      }
    }
    stage('Archive') {
      steps {
        archiveArtifacts artifacts: "**/target/*.jar", fingerprint: true
      }
    }    
    stage('Sonar Scanner') {
      steps {
        withSonarQubeEnv('SonarQube') { 
          sh 'mvn sonar:sonar -Dsonar.projectKey=GS -Dsonar.sources=src/main/java/com/kibernumacademy/devops -Dsonar.tests=src/test/java/com/kibernumacademy/devops -Dsonar.java.binaries=.'
        }
      }
    }
    stage('Build and Push Image') {
      steps {
        withCredentials([string(credentialsId: 'ecr-repo-uri', variable: 'ECR_REPO_URI')]) {
          script {
            def gitCommitShort = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
            def imageName = "${ECR_REPO_URI}:${gitCommitShort}"
            def imageNameLatest = "${ECR_REPO_URI}:latest"
            echo "Git SHA commit (Short): ${gitCommitShort}"
            echo "ECR Image Name: ${imageName}"
            
            // Construir y etiquetar la imagen del Dockerfile con el SHA commit abreviado
            sh "docker build -t ${imageName} ."
            sh "docker build -t ${imageNameLatest} ."
            
            withCredentials([usernamePassword(credentialsId: 'ecr-credentials', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
              script {
                sh "aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID"
                sh "aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY"
                sh "aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin ${ECR_REPO_URI}"
              }
            }

            // Subir la imagen a ECR
            sh "docker push ${imageName}"
            sh "docker push ${imageNameLatest}"
          }
        }
      }
    }
  }
}
