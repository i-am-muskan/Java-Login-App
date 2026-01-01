pipeline {
    agent any

    environment {
    DOCKER_IMAGE = "harshitha30galla/java-login-app"
    DOCKER_CREDS = "dockerhub-creds"
    }

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main',
                url: "https://github.com/i-am-muskan/Java-Login-App.git"
            }

        }

        stage('Build Apllication') {
            steps {
                sh "mvn clean package"
            }
        }

        stage('Build Docker Image') {
            steps {

                sh "docker build -t $DOCKER_IMAGE:latest "
            }
        }
        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: DOCKER_CREDS
                    usernameVariable: 'DOCKER_USER'
                    passwordVariable: 'DOCKER_PASS'
                )]) {

                    sh """
                        echo "$DOCKER_PASS" | docker login -u $DOCKER_USER --password-stdin
                        docker push $DOCKER_IMAGE:latest
                    """
                }
            }
            
        }
        
    }

    
}
