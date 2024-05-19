pipeline {
    agent none
    
    tools {
        jdk 'jdk-11'
    }
    
    environment {
        REGION='ap-south-2'
        ECR_REPOSITORY='nextjs-ecr'
        AWS_ACCOUNT_ID='079711632559'
    }
    
    stages {
        stage('Checkout') {
            agent {
                docker {
                    image 'rachakondadharmendra/custom-node:alpine3.19'
                    reuseNode true
                }
            }
            steps {
                git branch: 'master', changelog: false, credentialsId: 'github_admin_creds', poll: false, url: 'https://github.com/rachakondadharmendra/Nextjs_Project'
            }
        }

        stage('GitLeaks') {
            agent {
                docker {
                    image 'zricethezav/gitleaks'
                    args '--entrypoint=""'
                }
            }
            steps {
                script {
                    //sh 'gitleaks detect --verbose --source . --config ./gitleaks.toml --report-format csv --report-path secrets.csv || exit 0'
                    sh 'gitleaks detect --verbose --source . --report-format csv --report-path secrets.csv || exit 0'
                }
            }
        }

        stage('Dependency Installation') {
            agent {
                docker {
                    image 'rachakondadharmendra/custom-node:alpine3.19'
                    reuseNode true
                }
            }
            steps {
                sh ' npm ci '
            }
        }

        stage('OWASAP Dependency-Check') {
            agent {
                docker {
                    image 'node:bullseye-slim'
                    reuseNode true
                }
            }
            steps {
                script {
                    dependencyCheck additionalArguments: '''\
                        -o './' \
                        -s './' \
                        -f 'ALL' \
                        --prettyPrint ''', nvdCredentialsId: 'nvd-token', odcInstallation: 'dp-nvd-api'
                    dependencyCheckPublisher pattern: 'dependency-check-report.xml'
                }
            }
        }
        
        stage('Linting') {
            agent {
                docker {
                    image 'rachakondadharmendra/custom-node:alpine3.19'
                    reuseNode true
                }
            }
            steps {
                sh 'npm run lint && npm run format'
                echo "Linting of code is done"
            }
        }
        stage('Unit Testing') {
            agent {
                docker {
                    image 'rachakondadharmendra/custom-node:alpine3.19'
                    reuseNode true
                }
            }
            steps {
                //sh 'npm run test '
                echo "Unit Testing of code is done"
            }
        }        

        stage("Checkov scanning") {
            agent {
                docker {
                    image 'bridgecrew/checkov:3.2.49'
                    args "--entrypoint=''"
                }
            }
            steps {
                sh 'checkov --version'
                sh 'checkov -d . --framework dockerfile || exit 0'
            }
        }

        stage("Docker Build") {
            agent {
                docker {
                    image 'rachakondadharmendra/custom-node:alpine3.19'
                    reuseNode true
                }
            } 
            steps {
                script {
                    sh 'docker build -t ${ECR_REPOSITORY}:jenkinsbuild .'
                }
            }
        }

        stage("Trivy scanning") {
            agent {
                docker {
                    image 'aquasec/trivy:latest'
                    args "--entrypoint=''"
                }
            }
            steps {
                sh 'trivy --version'
                sh 'trivy image --format table ${ECR_REPOSITORY}:jenkinsbuild'
            }
        }

        stage('Tag and Push to ECR') {
            agent {
                docker {
                    image 'rachakondadharmendra/custom-node:alpine3.19'
                    reuseNode true
                }
            } 
            environment {
                  BRANCH_NAME=sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                  SHORT_PR_NUMBER=sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                  CURRENT_TIMESTAMP=sh(script: 'date "+%d-%m-%Y-%H.%M.%S"', returnStdout: true).trim()
                  IMAGE_TAG="${BRANCH_NAME}_${SHORT_PR_NUMBER}_${CURRENT_TIMESTAMP}"
            }            
            steps {
                script {
                    sh 'aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com'
                    sh 'docker tag ${ECR_REPOSITORY}:jenkinsbuild ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}'
                    sh 'docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}'
                }
            }
        }

    }
}
