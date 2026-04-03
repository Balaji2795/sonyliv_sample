pipeline {
    agent any

    environment {
        SONARQUBE = 'sq'
        DOCKER_IMAGE = 'Jenkinsfilee/sonyliv:latest'
        NEXUS_URL = 'http://13.233.172.129:8081'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scmGit(
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        credentialsId: 'GitCred',
                        url: 'https://github.com/CVN9696/sonyliv_sample.git'
                    ]]
                )
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Upload to Nexus') {
            steps {
                sh """
                curl -v -u admin:admin123 --upload-file target/*.jar \
                ${NEXUS_URL}/repository/maven-releases/
                """
            }
        }

        stage('Remove Old Docker Image') {
            steps {
                sh """
                docker rmi -f ${DOCKER_IMAGE}:latest || true
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${DOCKER_IMAGE}:latest .
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-creds',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh """
                    echo $PASS | docker login -u $USER --password-stdin
                    docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                kubectl set image deployment/sonyliv \
                sonyliv=${DOCKER_IMAGE}:latest
                """
            }
        }
    }
}
