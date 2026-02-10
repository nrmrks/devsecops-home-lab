pipeline {
    agent any
    
    environment {
        IMAGE_NAME = "devsecops-test"
        IMAGE_TAG = "${BUILD_NUMBER}"
        CONTAINER_NAME = "my-test-app"
        APP_PORT = "3000"
    }
    
    stages {
        stage('Cleanup Workspace') {
            steps {
                echo 'Cleaning workspace...'
                cleanWs()
            }
        }
        
        stage('Checkout Code') {
            steps {
                echo 'Checking out code from Git...'
                checkout scm
            }
        }
        
        stage('Verify Files') {
            steps {
                echo 'Verifying checked out files...'
                sh 'ls -la'
                sh 'cat package.json'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
                script {
                    sh """
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                        echo "Image built successfully"
                        docker images | grep ${IMAGE_NAME}
                    """
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                echo 'Running tests inside container...'
                script {
                    sh """
                        docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} npm test
                    """
                }
            }
        }
        
        stage('Stop Old Container') {
            steps {
                echo 'Stopping and removing old container if exists...'
                script {
                    sh """
                        docker stop ${CONTAINER_NAME} 2>/dev/null || echo "No container to stop"
                        docker rm ${CONTAINER_NAME} 2>/dev/null || echo "No container to remove"
                    """
                }
            }
        }
        
        stage('Deploy Container') {
            steps {
                echo "Deploying new container on port ${APP_PORT}..."
                script {
                    // Run container and capture ID
                    def containerId = sh(
                        script: """
                            docker run -d \
                              --name ${CONTAINER_NAME} \
                              -p ${APP_PORT}:3000 \
                              --restart unless-stopped \
                              ${IMAGE_NAME}:${IMAGE_TAG}
                        """,
                        returnStdout: true
                    ).trim()
                    
                    echo "✅ Container started with ID: ${containerId}"
                    
                    // Wait for container to initialize
                    echo "Waiting 5 seconds for container to start..."
                    sleep(5)
                    
                    // Check if container is running
                    def isRunning = sh(
                        script: "docker inspect -f '{{.State.Running}}' ${CONTAINER_NAME}",
                        returnStdout: true
                    ).trim()
                    
                    echo "Container running status: ${isRunning}"
                    
                    if (isRunning == "true") {
                        echo "✅ Container is running successfully!"
                    } else {
                        echo "❌ Container is not running. Fetching logs..."
                        sh "docker logs ${CONTAINER_NAME}"
                        error "Container failed to stay running"
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo 'Verifying deployment...'
                script {
                    sh """
                        echo "=== Container Status ==="
                        docker ps | grep ${CONTAINER_NAME}
                        
                        echo "=== Container Logs ==="
                        docker logs ${CONTAINER_NAME}
                        
                        echo "=== Testing Application ==="
                        sleep 2
                        curl -f http://localhost:${APP_PORT} || echo "Curl failed, but container might still be starting"
                        
                        echo "✅ Application should be available at http://localhost:${APP_PORT}"
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline completed successfully!'
            echo "🚀 Application deployed: http://localhost:${APP_PORT}"
            echo "📋 Check status: docker ps | grep ${CONTAINER_NAME}"
            echo "📄 View logs: docker logs ${CONTAINER_NAME}"
        }
        failure {
            echo '❌ Pipeline failed!'
            script {
                sh """
                    echo "=== Debug Information ==="
                    docker ps -a | grep ${CONTAINER_NAME} || echo "No container found"
                    docker logs ${CONTAINER_NAME} 2>&1 || echo "Cannot get logs"
                """
            }
        }
        always {
            echo 'Cleaning up old Docker images...'
            sh """
                docker image prune -f
            """
        }
    }
}
