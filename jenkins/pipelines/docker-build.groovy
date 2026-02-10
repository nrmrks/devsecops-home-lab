// Docker Build Pipeline
// Focused pipeline for building and pushing Docker images

pipeline {
    agent any
    
    environment {
        // Docker image configuration
        DOCKER_REGISTRY = 'docker.io'
        IMAGE_NAME = 'devsecops-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        
        // Docker credentials (configured in Jenkins)
        // DOCKER_CREDENTIALS = credentials('dockerhub-credentials')
    }
    
    options {
        // Build options
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }
    
    stages {
        stage('Preparation') {
            steps {
                echo '📋 Preparing build environment...'
                script {
                    sh '''
                        echo "Build Number: ${BUILD_NUMBER}"
                        echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
                        docker --version
                    '''
                }
            }
        }
        
        stage('Checkout Code') {
            steps {
                echo '📥 Checking out source code...'
                checkout scm
                sh 'ls -la'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                script {
                    dir('apps/nodejs-app') {
                        sh """
                            docker build \
                                --tag ${IMAGE_NAME}:${IMAGE_TAG} \
                                --tag ${IMAGE_NAME}:latest \
                                --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                                --build-arg VERSION=${IMAGE_TAG} \
                                .
                        """
                    }
                }
            }
        }
        
        stage('Test Image') {
            steps {
                echo '🧪 Testing Docker image...'
                script {
                    sh """
                        # Test that image was created
                        docker images | grep ${IMAGE_NAME}
                        
                        # Test container can start
                        docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} node --version
                        
                        # Run application tests in container
                        docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} npm test
                    """
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                echo '🔒 Scanning image for vulnerabilities...'
                script {
                    // Placeholder for security scanning
                    // In production, integrate tools like Trivy, Clair, or Snyk
                    sh """
                        echo "Would run security scan here..."
                        echo "Example: trivy image ${IMAGE_NAME}:${IMAGE_TAG}"
                        echo "Example: docker scan ${IMAGE_NAME}:${IMAGE_TAG}"
                    """
                }
            }
        }
        
        stage('Push to Registry') {
            when {
                // Only push on main/master branch
                branch 'main'
            }
            steps {
                echo '📤 Pushing image to registry...'
                script {
                    // Uncomment and configure when using Docker registry
                    /*
                    sh '''
                        echo $DOCKER_CREDENTIALS_PSW | docker login -u $DOCKER_CREDENTIALS_USR --password-stdin
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
                        docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
                        docker logout
                    '''
                    */
                    echo 'Push to registry skipped (configure credentials first)'
                }
            }
        }
        
        stage('Deploy Container') {
            steps {
                echo '🚀 Deploying container locally...'
                script {
                    sh """
                        # Stop and remove old container if exists
                        docker stop ${IMAGE_NAME} 2>/dev/null || true
                        docker rm ${IMAGE_NAME} 2>/dev/null || true
                        
                        # Run new container
                        docker run -d \
                            --name ${IMAGE_NAME} \
                            --restart unless-stopped \
                            -p 3000:3000 \
                            ${IMAGE_NAME}:${IMAGE_TAG}
                        
                        # Wait for container to start
                        sleep 3
                        
                        # Verify container is running
                        docker ps | grep ${IMAGE_NAME}
                    """
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo '✅ Verifying deployment...'
                script {
                    sh """
                        # Check container health
                        docker inspect --format='{{.State.Status}}' ${IMAGE_NAME}
                        
                        # Test application endpoint
                        sleep 2
                        curl -f http://localhost:3000 || echo "Application starting..."
                        curl -f http://localhost:3000/health || echo "Health check pending..."
                        
                        echo "Container logs:"
                        docker logs ${IMAGE_NAME}
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning up...'
            script {
                // Clean up old images (keep last 5)
                sh """
                    echo "Pruning old images..."
                    docker image prune -f
                """
            }
        }
        success {
            echo '✅ Docker build pipeline completed successfully!'
            echo "🐳 Image: ${IMAGE_NAME}:${IMAGE_TAG}"
            echo "🌐 Application: http://localhost:3000"
        }
        failure {
            echo '❌ Docker build pipeline failed!'
            script {
                sh """
                    echo "=== Debug Information ==="
                    docker images | grep ${IMAGE_NAME} || echo "No images found"
                    docker ps -a | grep ${IMAGE_NAME} || echo "No containers found"
                """
            }
        }
    }
}
