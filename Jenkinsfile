pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'vamsichamarthi/sonyliv'
        IMAGE_TAG = "${BUILD_NUMBER}"
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

        stage('Verify Files') {
            steps {
                sh 'ls -la'
            }
        }

       stage('SonarQube Scan') {
    steps {
        script {
            def scannerHome = tool 'SonarScanner'
            withSonarQubeEnv('sq') {
                withCredentials([string(
                    credentialsId: 'Sonarqube_token',
                    variable: 'SONAR_TOKEN'
                )]) {
                    sh '''
                    ${scannerHome}/bin/sonar-scanner \
                    -Dsonar.projectKey=sonyliv \
                    -Dsonar.sources=. \
                    -Dsonar.host.url=$SONAR_HOST_URL \
                    -Dsonar.login=$SONAR_TOKEN
                    '''
                }
            }
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
                    credentialsId: 'docker-cred',
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
        failure {
            sh 'kubectl rollout undo deployment/sonyliv || true'
        }
        always {
            cleanWs()
        }
    }
}
