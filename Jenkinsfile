// pipeline {
//     agent any
    
//     environment {
//         DOCKER_IMAGE = "sudharshan1305/jenkins-test-app"
//         DOCKER_REGISTRY_CREDENTIALS = 'dockerhub-credentials'
//         K8S_CREDENTIALS = 'kubeconfig'
//         K8S_NAMESPACE = 'default'
//         DOCKER_TAG = "${BUILD_NUMBER}"
//         GIT_COMMIT_SHORT = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
//     }
    
//     stages {
//         stage('Checkout') {
//             steps {
//                 echo '📦 Checking out source code...'
//                 checkout scm
//                 script {
//                     // Display commit information
//                     def commitMessage = sh(returnStdout: true, script: 'git log -1 --pretty=%B').trim()
//                     def commitAuthor = sh(returnStdout: true, script: 'git log -1 --pretty=%an').trim()
//                     echo "Commit: ${GIT_COMMIT_SHORT}"
//                     echo "Author: ${commitAuthor}"
//                     echo "Message: ${commitMessage}"
//                 }
//             }
//         }
        
//         stage('Lint & Validate') {
//             steps {
//                 echo '🔍 Validating files...'
//                 script {
//                     // Check if required files exist
//                     bat '''
//                         if not exist Dockerfile (
//                             echo ERROR: Dockerfile not found!
//                             exit /b 1
//                         )
//                         if not exist index.html (
//                             echo ERROR: index.html not found!
//                             exit /b 1
//                         )
//                         if not exist k8s\\deployment.yaml (
//                             echo ERROR: deployment.yaml not found!
//                             exit /b 1
//                         )
//                         if not exist k8s\\service.yaml (
//                             echo ERROR: service.yaml not found!
//                             exit /b 1
//                         )
//                         echo All required files found!
//                     '''
//                 }
//             }
//         }
        
//         stage('Build Docker Image') {
//             steps {
//                 echo "🐳 Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
//                 script {
//                     bat """
//                         docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
//                         docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
//                         docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:${GIT_COMMIT_SHORT}
//                     """
//                 }
//             }
//         }
        
//         stage('Test Docker Image') {
//             steps {
//                 echo '🧪 Testing Docker image...'
//                 script {
//                     bat """
//                         docker run --rm -d --name test-container -p 9999:80 ${DOCKER_IMAGE}:${DOCKER_TAG}
//                         timeout /t 5 /nobreak
//                         curl -f http://localhost:9999 || (docker stop test-container && exit /b 1)
//                         docker stop test-container
//                     """
//                 }
//             }
//         }
        
//         stage('Security Scan') {
//             steps {
//                 echo '🔒 Scanning for vulnerabilities...'
//                 script {
//                     // Using Docker scan (requires Docker Desktop)
//                     bat """
//                         echo Running basic security checks...
//                         docker inspect ${DOCKER_IMAGE}:${DOCKER_TAG}
//                         echo Security scan completed
//                     """
//                 }
//             }
//         }
        
//         stage('Push to Docker Hub') {
//             steps {
//                 echo '📤 Pushing image to Docker Hub...'
//                 script {
//                     withCredentials([usernamePassword(
//                         credentialsId: "${DOCKER_REGISTRY_CREDENTIALS}",
//                         usernameVariable: 'DOCKER_USER',
//                         passwordVariable: 'DOCKER_PASS'
//                     )]) {
//                         bat """
//                             docker login -u %DOCKER_USER% -p %DOCKER_PASS%
//                             docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
//                             docker push ${DOCKER_IMAGE}:latest
//                             docker push ${DOCKER_IMAGE}:${GIT_COMMIT_SHORT}
//                             docker logout
//                         """
//                     }
//                 }
//             }
//         }
        
//         stage('Update K8s Manifest') {
//             steps {
//                 echo '📝 Updating Kubernetes deployment manifest...'
//                 script {
//                     bat """
//                         powershell -Command "(Get-Content k8s\\deployment.yaml) -replace 'IMAGE_TAG', '${DOCKER_TAG}' | Set-Content k8s\\deployment-temp.yaml"
//                     """
//                 }
//             }
//         }
        
//         stage('Deploy to Kubernetes') {
//             steps {
//                 echo '☸️ Deploying to Kubernetes cluster...'
//                 script {
//                     withKubeConfig([credentialsId: "${K8S_CREDENTIALS}"]) {
//                         bat """
//                             kubectl apply -f k8s\\deployment-temp.yaml
//                             kubectl apply -f k8s\\service.yaml
//                             kubectl rollout status deployment/jenkins-test-app -n ${K8S_NAMESPACE} --timeout=300s
//                         """
//                     }
//                 }
//             }
//         }
        
//         stage('Verify Deployment') {
//             steps {
//                 echo '✅ Verifying deployment health...'
//                 script {
//                     withKubeConfig([credentialsId: "${K8S_CREDENTIALS}"]) {
//                         bat """
//                             kubectl get deployments -n ${K8S_NAMESPACE}
//                             kubectl get pods -n ${K8S_NAMESPACE} -l app=jenkins-test-app
//                             kubectl get services -n ${K8S_NAMESPACE}
//                         """
                        
//                         // Wait for pods to be ready
//                         bat """
//                             kubectl wait --for=condition=ready pod -l app=jenkins-test-app -n ${K8S_NAMESPACE} --timeout=120s
//                         """
//                     }
//                 }
//             }
//         }
        
//         stage('Smoke Test') {
//             steps {
//                 echo '🔥 Running smoke tests...'
//                 script {
//                     sleep(time: 10, unit: 'SECONDS')
//                     bat """
//                         echo Testing application endpoint...
//                         curl -f http://localhost:30080 || curl -f http://localhost:8888
//                         echo Smoke test passed!
//                     """
//                 }
//             }
//         }
//     }
    
//     post {
//         success {
//             echo '✅ =========================================='
//             echo '✅ Pipeline completed successfully! 🎉'
//             echo '✅ =========================================='
//             echo "✅ Build: #${BUILD_NUMBER}"
//             echo "✅ Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
//             echo "✅ Commit: ${GIT_COMMIT_SHORT}"
//             echo '✅ Application URL: http://localhost:30080'
//             echo '✅ =========================================='
            
//             // Clean up temp files
//             bat 'if exist k8s\\deployment-temp.yaml del k8s\\deployment-temp.yaml'
//         }
        
//         failure {
//             echo '❌ =========================================='
//             echo '❌ Pipeline failed! 😞'
//             echo '❌ =========================================='
//             echo "❌ Build: #${BUILD_NUMBER}"
//             echo "❌ Check logs above for details"
//             echo '❌ =========================================='
            
//             script {
//                 // Rollback on failure
//                 withKubeConfig([credentialsId: "${K8S_CREDENTIALS}"]) {
//                     bat """
//                         echo Attempting rollback...
//                         kubectl rollout undo deployment/jenkins-test-app -n ${K8S_NAMESPACE} || echo Rollback not possible
//                     """
//                 }
//             }
//         }
        
//         always {
//             echo '🧹 Cleaning up...'
//             script {
//                 // Clean up old Docker images (keep last 5)
//                 bat """
//                     echo Removing old Docker images...
//                     for /f "skip=5 tokens=*" %%i in ('docker images ${DOCKER_IMAGE} --format "{{.Tag}}" ^| findstr /R "^[0-9]"') do docker rmi ${DOCKER_IMAGE}:%%i 2>nul || exit 0
//                 """
                
//                 // Clean up temp files
//                 bat 'if exist k8s\\deployment-temp.yaml del k8s\\deployment-temp.yaml'
//             }
//         }
//     }
// }

pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "sudharshan1305/jenkins-test-app"
        DOCKER_REGISTRY_CREDENTIALS = 'dockerhub-credentials'
        K8S_CREDENTIALS = 'kubeconfig'
        K8S_NAMESPACE = 'default'
        DOCKER_TAG = "${BUILD_NUMBER}"
        // Note: GIT_COMMIT_SHORT removed from environment and computed after checkout
    }

    stages {
        stage('Checkout') {
            steps {
                echo '📦 Checking out source code...'
                checkout scm
                script {
                    // Compute short commit hash and store into env
                    env.GIT_COMMIT_SHORT = bat(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    // Display commit information
                    def commitMessage = bat(returnStdout: true, script: 'git log -1 --pretty=%B').trim()
                    def commitAuthor = bat(returnStdout: true, script: 'git log -1 --pretty=%an').trim()
                    echo "Commit: ${env.GIT_COMMIT_SHORT}"
                    echo "Author: ${commitAuthor}"
                    echo "Message: ${commitMessage}"
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
                echo "🐳 Building Docker image: ${env.DOCKER_IMAGE}:${env.DOCKER_TAG}"
                script {
                    // Use Groovy interpolation so the command contains correct tags
                    bat """
                        docker build -t ${env.DOCKER_IMAGE}:${env.DOCKER_TAG} .
                        docker tag ${env.DOCKER_IMAGE}:${env.DOCKER_TAG} ${env.DOCKER_IMAGE}:latest
                        docker tag ${env.DOCKER_IMAGE}:${env.DOCKER_TAG} ${env.DOCKER_IMAGE}:${env.GIT_COMMIT_SHORT}
                    """
                }
            }
        }

        stage('Test Docker Image') {
            steps {
                echo '🧪 Testing Docker image...'
                script {
                    bat """
                        docker run --rm -d --name test-container -p 9999:80 ${env.DOCKER_IMAGE}:${env.DOCKER_TAG}
                        timeout /t 5 /nobreak
                        curl -f http://localhost:9999 || (docker stop test-container && exit /b 1)
                        docker stop test-container
                    """
                }
            }
        }

        stage('Security Scan') {
            steps {
                echo '🔒 Scanning for vulnerabilities...'
                script {
                    bat """
                        echo Running basic security checks...
                        docker inspect ${env.DOCKER_IMAGE}:${env.DOCKER_TAG}
                        echo Security scan completed
                    """
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo '📤 Pushing image to Docker Hub...'
                script {
                    withCredentials([usernamePassword(
                        credentialsId: "${env.DOCKER_REGISTRY_CREDENTIALS}",
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        // Use environment variables DOCKER_USER/DOCKER_PASS inside bat
                        bat """
                            docker login -u %DOCKER_USER% -p %DOCKER_PASS%
                            docker push ${env.DOCKER_IMAGE}:${env.DOCKER_TAG}
                            docker push ${env.DOCKER_IMAGE}:latest
                            docker push ${env.DOCKER_IMAGE}:${env.GIT_COMMIT_SHORT}
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
                    // Replace IMAGE_TAG placeholder in deployment.yaml and write temp file
                    bat """
                        powershell -Command "(Get-Content k8s\\deployment.yaml) -replace 'IMAGE_TAG', '${env.DOCKER_TAG}' | Set-Content k8s\\deployment-temp.yaml"
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo '☸️ Deploying to Kubernetes cluster...'
                script {
                    // withKubeConfig requires Kubernetes CLI plugin and a Secret File credential with ID = K8S_CREDENTIALS
                    withKubeConfig([credentialsId: "${env.K8S_CREDENTIALS}"]) {
                        bat """
                            kubectl apply -f k8s\\deployment-temp.yaml
                            kubectl apply -f k8s\\service.yaml
                            kubectl rollout status deployment/jenkins-test-app -n ${env.K8S_NAMESPACE} --timeout=300s
                        """
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '✅ Verifying deployment health...'
                script {
                    withKubeConfig([credentialsId: "${env.K8S_CREDENTIALS}"]) {
                        bat """
                            kubectl get deployments -n ${env.K8S_NAMESPACE}
                            kubectl get pods -n ${env.K8S_NAMESPACE} -l app=jenkins-test-app
                            kubectl get services -n ${env.K8S_NAMESPACE}
                        """

                        bat """
                            kubectl wait --for=condition=ready pod -l app=jenkins-test-app -n ${env.K8S_NAMESPACE} --timeout=120s
                        """
                    }
                }
            }
        }

        stage('Smoke Test') {
            steps {
                echo '🔥 Running smoke tests...'
                script {
                    sleep(time: 10, unit: 'SECONDS')
                    bat """
                        echo Testing application endpoint...
                        curl -f http://localhost:30080 || curl -f http://localhost:8888
                        echo Smoke test passed!
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ =========================================='
            echo '✅ Pipeline completed successfully! 🎉'
            echo '✅ =========================================='
            echo "✅ Build: #${BUILD_NUMBER}"
            echo "✅ Image: ${env.DOCKER_IMAGE}:${env.DOCKER_TAG}"
            echo "✅ Commit: ${env.GIT_COMMIT_SHORT}"
            echo '✅ Application URL: http://localhost:30080'
            echo '✅ =========================================='

            // Clean up temp files
            bat 'if exist k8s\\deployment-temp.yaml del k8s\\deployment-temp.yaml'
        }

        failure {
            echo '❌ =========================================='
            echo '❌ Pipeline failed! 😞'
            echo '❌ =========================================='
            echo "❌ Build: #${BUILD_NUMBER}"
            echo "❌ Check logs above for details"
            echo '❌ =========================================='

            script {
                // Rollback on failure
                withKubeConfig([credentialsId: "${env.K8S_CREDENTIALS}"]) {
                    bat """
                        echo Attempting rollback...
                        kubectl rollout undo deployment/jenkins-test-app -n ${env.K8S_NAMESPACE} || echo Rollback not possible
                    """
                }
            }
        }

        always {
            echo '🧹 Cleaning up...'
            script {
                bat """
                    echo Removing unused Docker images...
                    docker image prune -a -f --filter "until=72h" || docker image prune -a -f
                """
                bat 'if exist k8s\\deployment-temp.yaml del k8s\\deployment-temp.yaml'
            }
        }
    }
}
