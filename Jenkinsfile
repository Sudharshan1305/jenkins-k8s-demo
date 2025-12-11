pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = "sudharshan1305/jenkins-test-app"
        DOCKER_REGISTRY_CREDENTIALS = 'dockerhub-credentials'
        K8S_CREDENTIALS = 'kubeconfig'
        K8S_NAMESPACE = 'default'
        DOCKER_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📦 Checking out source code...'
                checkout scm
                script {
                    // Display commit information (Windows compatible)
                    bat 'git log -1 --pretty=%%B > commit_msg.txt'
                    bat 'git log -1 --pretty=%%an > commit_author.txt'
                    bat 'git rev-parse --short HEAD > commit_hash.txt'
                    
                    def commitMessage = readFile('commit_msg.txt').trim()
                    def commitAuthor = readFile('commit_author.txt').trim()
                    def commitHash = readFile('commit_hash.txt').trim()
                    
                    echo "Commit: ${commitHash}"
                    echo "Author: ${commitAuthor}"
                    echo "Message: ${commitMessage}"
                    
                    // Cleanup temp files
                    bat 'del commit_msg.txt commit_author.txt commit_hash.txt'
                }
            }
        }
        
        stage('Lint & Validate') {
            steps {
                echo '🔍 Validating files...'
                script {
                    bat '''
                        if not exist Dockerfile (
                            echo ERROR: Dockerfile not found!
                            exit /b 1
                        )
                        if not exist index.html (
                            echo ERROR: index.html not found!
                            exit /b 1
                        )
                        if not exist k8s\\deployment.yaml (
                            echo ERROR: deployment.yaml not found!
                            exit /b 1
                        )
                        if not exist k8s\\service.yaml (
                            echo ERROR: service.yaml not found!
                            exit /b 1
                        )
                        echo All required files found!
                    '''
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                script {
                    bat """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                echo '🧪 Testing Docker image...'
                script {
                    bat """
                        docker run --rm -d --name test-container -p 9999:80 ${DOCKER_IMAGE}:${DOCKER_TAG}
                        timeout /t 5 /nobreak
                        curl -f http://localhost:9999 || (docker stop test-container & exit /b 1)
                        docker stop test-container
                    """
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                echo '📤 Pushing image to Docker Hub...'
                script {
                    withCredentials([usernamePassword(
                        credentialsId: "${DOCKER_REGISTRY_CREDENTIALS}",
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        bat """
                            docker login -u %DOCKER_USER% -p %DOCKER_PASS%
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                            docker logout
                        """
                    }
                }
            }
        }
        
        stage('Update K8s Manifest') {
            steps {
                echo '📝 Updating Kubernetes deployment manifest...'
                script {
                    bat """
                        powershell -Command "(Get-Content k8s\\deployment.yaml) -replace 'IMAGE_TAG', '${DOCKER_TAG}' | Set-Content k8s\\deployment-temp.yaml"
                    """
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                echo '☸️ Deploying to Kubernetes cluster...'
                script {
                    withKubeConfig([credentialsId: "${K8S_CREDENTIALS}"]) {
                        bat """
                            kubectl apply -f k8s\\deployment-temp.yaml
                            kubectl apply -f k8s\\service.yaml
                            kubectl rollout status deployment/jenkins-test-app -n ${K8S_NAMESPACE} --timeout=300s
                        """
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo '✅ Verifying deployment health...'
                script {
                    withKubeConfig([credentialsId: "${K8S_CREDENTIALS}"]) {
                        bat """
                            kubectl get deployments -n ${K8S_NAMESPACE}
                            kubectl get pods -n ${K8S_NAMESPACE} -l app=jenkins-test-app
                            kubectl get services -n ${K8S_NAMESPACE}
                        """
                        
                        bat """
                            kubectl wait --for=condition=ready pod -l app=jenkins-test-app -n ${K8S_NAMESPACE} --timeout=120s
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            script {
                echo '✅ =========================================='
                echo '✅ Pipeline completed successfully! 🎉'
                echo '✅ =========================================='
                echo "✅ Build: #${env.BUILD_NUMBER}"
                echo "✅ Image: ${env.DOCKER_IMAGE}:${env.DOCKER_TAG}"
                echo '✅ Application URL: http://localhost:30080'
                echo '✅ =========================================='
                
                // Clean up temp files
                bat 'if exist k8s\\deployment-temp.yaml del k8s\\deployment-temp.yaml'
            }
        }
        
        failure {
            script {
                echo '❌ =========================================='
                echo '❌ Pipeline failed! 😞'
                echo '❌ =========================================='
                echo "❌ Build: #${env.BUILD_NUMBER}"
                echo '❌ Check logs above for details'
                echo '❌ =========================================='
                
                // Attempt rollback
                try {
                    withKubeConfig([credentialsId: "${env.K8S_CREDENTIALS}"]) {
                        bat """
                            echo Attempting rollback...
                            kubectl rollout undo deployment/jenkins-test-app -n ${env.K8S_NAMESPACE}
                        """
                    }
                } catch (Exception e) {
                    echo "Rollback failed or not possible: ${e.message}"
                }
            }
        }
        
        always {
            script {
                echo '🧹 Cleaning up...'
                
                // Clean up old Docker images (keep last 5)
                try {
                    bat """
                        echo Removing old Docker images...
                        for /f "skip=5 tokens=*" %%i in ('docker images ${env.DOCKER_IMAGE} --format "{{.Tag}}" ^| findstr /R "^[0-9]"') do docker rmi ${env.DOCKER_IMAGE}:%%i 2^>nul
                    """
                } catch (Exception e) {
                    echo "Image cleanup failed: ${e.message}"
                }
                
                // Clean up temp files
                bat 'if exist k8s\\deployment-temp.yaml del k8s\\deployment-temp.yaml 2>nul'
            }
        }
    }
}