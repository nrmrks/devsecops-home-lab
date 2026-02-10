// Security Scan Pipeline
// Example pipeline integrating security scanning at multiple stages
// This demonstrates DevSecOps "shift-left" security practices

pipeline {
    agent any
    
    environment {
        APP_NAME = 'devsecops-app'
        SCAN_RESULTS_DIR = 'security-scan-results'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 45, unit: 'MINUTES')
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📥 Checking out source code...'
                checkout scm
            }
        }
        
        stage('Secret Scanning') {
            steps {
                echo '🔐 Scanning for secrets and credentials...'
                script {
                    // Placeholder for secret scanning tools
                    // Examples: git-secrets, truffleHog, detect-secrets
                    sh '''
                        echo "=== Secret Scanning ==="
                        echo "Scanning for hardcoded secrets, API keys, passwords..."
                        
                        # Example: Check for common patterns
                        echo "Checking for potential secrets in code..."
                        
                        # In production, use tools like:
                        # - truffleHog: truffleHog --regex --entropy=False .
                        # - git-secrets: git secrets --scan
                        # - GitGuardian: ggshield scan path .
                        
                        echo "✅ No secrets detected (placeholder check)"
                    '''
                }
            }
        }
        
        stage('Dependency Check') {
            steps {
                echo '📦 Checking dependencies for vulnerabilities...'
                script {
                    dir('apps/nodejs-app') {
                        sh '''
                            echo "=== Dependency Security Audit ==="
                            
                            # NPM audit (built-in)
                            echo "Running npm audit..."
                            npm audit --json > ../../${SCAN_RESULTS_DIR}/npm-audit.json || true
                            npm audit || echo "Vulnerabilities found - review required"
                            
                            # In production, also consider:
                            # - Snyk: snyk test --json > snyk-results.json
                            # - OWASP Dependency-Check: dependency-check.sh --scan ./
                            # - RetireJS: retire --outputformat json
                        '''
                    }
                }
            }
        }
        
        stage('SAST - Static Analysis') {
            steps {
                echo '🔍 Running static code analysis...'
                script {
                    sh '''
                        echo "=== Static Application Security Testing (SAST) ==="
                        
                        # Placeholder for SAST tools
                        # Examples of SAST tools:
                        
                        # 1. SonarQube Scanner
                        # sonar-scanner \
                        #   -Dsonar.projectKey=devsecops-app \
                        #   -Dsonar.sources=. \
                        #   -Dsonar.host.url=http://sonarqube:9000
                        
                        # 2. ESLint (JavaScript)
                        # cd apps/nodejs-app
                        # npm install -D eslint
                        # npx eslint . --format json > ../../${SCAN_RESULTS_DIR}/eslint-results.json
                        
                        # 3. Semgrep
                        # semgrep --config auto --json > ${SCAN_RESULTS_DIR}/semgrep-results.json
                        
                        echo "✅ Static analysis complete (placeholder)"
                    '''
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                script {
                    dir('apps/nodejs-app') {
                        sh """
                            docker build -t ${APP_NAME}:${BUILD_NUMBER} .
                            docker tag ${APP_NAME}:${BUILD_NUMBER} ${APP_NAME}:latest
                        """
                    }
                }
            }
        }
        
        stage('Container Image Scan') {
            steps {
                echo '🔒 Scanning container image for vulnerabilities...'
                script {
                    sh """
                        echo "=== Container Image Security Scan ==="
                        
                        # Placeholder for container scanning tools
                        
                        # 1. Trivy (recommended - easy to use)
                        # trivy image --severity HIGH,CRITICAL ${APP_NAME}:${BUILD_NUMBER}
                        # trivy image --format json --output ${SCAN_RESULTS_DIR}/trivy-results.json ${APP_NAME}:${BUILD_NUMBER}
                        
                        # 2. Clair
                        # clair-scanner --ip localhost ${APP_NAME}:${BUILD_NUMBER}
                        
                        # 3. Anchore
                        # anchore-cli image add ${APP_NAME}:${BUILD_NUMBER}
                        # anchore-cli image wait ${APP_NAME}:${BUILD_NUMBER}
                        # anchore-cli image vuln ${APP_NAME}:${BUILD_NUMBER}
                        
                        # 4. Snyk Container
                        # snyk container test ${APP_NAME}:${BUILD_NUMBER}
                        
                        echo "✅ Container scan complete (placeholder)"
                    """
                }
            }
        }
        
        stage('IaC Security Scan') {
            steps {
                echo '📋 Scanning Infrastructure as Code...'
                script {
                    sh '''
                        echo "=== Infrastructure as Code Security ==="
                        
                        # Scan Dockerfiles
                        echo "Scanning Dockerfiles for best practices..."
                        
                        # Examples:
                        # 1. Hadolint (Dockerfile linter)
                        # hadolint apps/nodejs-app/Dockerfile
                        
                        # 2. Checkov (for various IaC)
                        # checkov -d . --framework dockerfile
                        
                        # 3. Terrascan
                        # terrascan scan -t docker
                        
                        echo "✅ IaC scan complete (placeholder)"
                    '''
                }
            }
        }
        
        stage('Deploy to Test Environment') {
            steps {
                echo '🚀 Deploying to test environment...'
                script {
                    sh """
                        # Stop old container
                        docker stop ${APP_NAME}-test 2>/dev/null || true
                        docker rm ${APP_NAME}-test 2>/dev/null || true
                        
                        # Deploy new container
                        docker run -d \
                            --name ${APP_NAME}-test \
                            -p 3000:3000 \
                            ${APP_NAME}:${BUILD_NUMBER}
                        
                        sleep 3
                        echo "Application deployed to test environment"
                    """
                }
            }
        }
        
        stage('DAST - Dynamic Analysis') {
            steps {
                echo '🎯 Running dynamic security testing...'
                script {
                    sh '''
                        echo "=== Dynamic Application Security Testing (DAST) ==="
                        
                        # Wait for application to be ready
                        sleep 5
                        
                        # Placeholder for DAST tools
                        
                        # 1. OWASP ZAP
                        # docker run -t owasp/zap2docker-stable zap-baseline.py \
                        #   -t http://host.docker.internal:3000 \
                        #   -J zap-report.json
                        
                        # 2. Nikto
                        # nikto -h http://localhost:3000 -output nikto-results.txt
                        
                        # 3. w3af
                        # w3af_console -y -s scripts/scan.w3af
                        
                        # Basic endpoint testing
                        curl -f http://localhost:3000 || echo "Endpoint check failed"
                        curl -f http://localhost:3000/health || echo "Health check failed"
                        
                        echo "✅ Dynamic analysis complete (placeholder)"
                    '''
                }
            }
        }
        
        stage('Security Report') {
            steps {
                echo '📊 Generating security report...'
                script {
                    sh """
                        echo "=== Security Scan Summary ==="
                        echo "Build Number: ${BUILD_NUMBER}"
                        echo "Timestamp: \$(date)"
                        echo ""
                        echo "Scans Performed:"
                        echo "✓ Secret Scanning"
                        echo "✓ Dependency Vulnerability Check"
                        echo "✓ Static Application Security Testing (SAST)"
                        echo "✓ Container Image Scanning"
                        echo "✓ Infrastructure as Code Security"
                        echo "✓ Dynamic Application Security Testing (DAST)"
                        echo ""
                        echo "Note: This is a template pipeline."
                        echo "Integrate actual security tools for production use."
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning up...'
            script {
                // Archive security scan results if they exist
                sh '''
                    if [ -d "${SCAN_RESULTS_DIR}" ]; then
                        echo "Security scan results available in ${SCAN_RESULTS_DIR}/"
                        ls -la ${SCAN_RESULTS_DIR}/ || true
                    fi
                '''
                
                // Clean up test container
                sh """
                    docker stop ${APP_NAME}-test 2>/dev/null || true
                    docker rm ${APP_NAME}-test 2>/dev/null || true
                """
            }
        }
        success {
            echo '✅ Security scan pipeline completed successfully!'
            echo '🔒 All security checks passed (template mode)'
        }
        failure {
            echo '❌ Security scan pipeline failed!'
            echo '⚠️  Review security findings before proceeding'
        }
    }
}

/*
 * INTEGRATION GUIDE
 * 
 * To integrate actual security tools:
 * 
 * 1. Install tools in Jenkins environment or use Docker containers
 * 2. Configure credentials for commercial tools (Snyk, etc.)
 * 3. Set up quality gates based on scan results
 * 4. Archive scan results as build artifacts
 * 5. Configure notifications for security findings
 * 
 * Recommended Tools by Category:
 * 
 * Secret Scanning:
 *   - TruffleHog, GitGuardian, git-secrets
 * 
 * Dependency Scanning:
 *   - npm audit, Snyk, OWASP Dependency-Check
 * 
 * SAST:
 *   - SonarQube, Semgrep, Checkmarx
 * 
 * Container Scanning:
 *   - Trivy, Clair, Anchore, Snyk Container
 * 
 * DAST:
 *   - OWASP ZAP, Burp Suite, Acunetix
 * 
 * IaC Security:
 *   - Checkov, Terrascan, tfsec, Hadolint
 */
