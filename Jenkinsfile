pipeline {
    agent any

    tools {
        maven 'Maven'
    }
 environment {
        SONARQUBE = 'sq'
        DOCKER_IMAGE = 'Jenkinsfilee/sonyliv'
        IMAGE_TAG = "${BUILD_NUMBER}"
        NEXUS_URL = 'http://13.233.172.129:8081'
    }
    
    triggers {
        githubPush()
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
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Upload Artifact to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-creds',
                    usernameVariable: 'NUSER',
                    passwordVariable: 'NPASS'
                )]) {
                    sh """
                    curl -u $NUSER:$NPASS --upload-file target/*.jar \
                    ${NEXUS_URL}
                    """
                }
            }
        }

        stage('Docker Cleanup') {
            steps {
                sh """
                docker rmi -f ${DOCKER_IMAGE}:${IMAGE_TAG} || true
                docker rmi -f ${DOCKER_IMAGE}:latest || true
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} .
                docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${DOCKER_IMAGE}:latest
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-creds',
                    usernameVariable: 'DUSER',
                    passwordVariable: 'DPASS'
                )]) {
                    sh """
                    echo $DPASS | docker login -u $DUSER --password-stdin
                    docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                kubectl set image deployment/sonyliv \
                sonyliv=${DOCKER_IMAGE}:${IMAGE_TAG}
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                sh 'kubectl rollout status deployment/sonyliv'
            }
        }
    }

    post {
        success {
            echo "✅ Deployment Successful - Version ${IMAGE_TAG}"
        }
        failure {
            echo "❌ Deployment Failed - Rolling Back"
            sh 'kubectl rollout undo deployment/sonyliv || true'
        }
        always {
            cleanWs()
        }
    }
}
