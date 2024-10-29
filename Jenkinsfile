pipeline {
    agent any
    
    tools{
        jdk 'jdk17'
        maven 'maven3'
    }
    
    environment{
        SCANNER_HOME= tool 'sonar-scanner'
    }

    stages {
        stage('Clean Worspace') {
            steps {
                cleanWs()
            }
        }
        
        stage('Git Checkout') {
            steps {
                git branch: 'main', changelog: false, poll: false, url: 'https://github.com/imadtoumi/Blue-Green-Deployment.git'
            }
        }
        
        stage('maven compile') {
            steps {
                sh 'mvn compile'
            }
        }
        
        stage('maven test') {
            steps {
                sh 'mvn test -DskipTests=true'
            }
        }
            
        stage('SonarQube code analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Blue-Green \
                    -Dsonar.projectKey=Blue-Green -Dsonar.java.binaries=target'''
                }
            }
        }
        
        stage('Sonar Quality Gate') {
            steps {
                waitForQualityGate abortPipeline: true, credentialsId: 'sonar-token'
            }
        }
        
        stage('Security / Vulnerabilty scanning') {
            steps {
                parallel(
                    'Dependency checking':{
                        dependencyCheck additionalArguments: '--scan ./ --format XML --out dependency_check.xml ', odcInstallation: 'owasp'
                        dependencyCheckPublisher pattern: 'dependency_check.xml'
                        archiveArtifacts artifacts: 'dependency_check.xml', allowEmptyArchive: false
                    },'Docker base image scanning':{
                        sh 'bash scan-baseImage.sh'
                    },'OPA - Docker file scan':{
                        sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy dockerfile-security.rego Dockerfile'
                    }    
                )
            }
        }
        
        stage('Maven package') {
            steps {
                sh 'mvn package -DskipTests=true'
            }
        }
        
        stage('Maven deploy artifacts to Nexus') {
            steps {
                withMaven(globalMavenSettingsConfig: 'setting-maven', jdk: 'jdk17', maven: 'maven3', mavenSettingsConfig: '', traceability: true) {
                    sh 'mvn deploy -DskipTests=true'
                }
            }
        }
        
        stage('Docker Build image') {
            steps {
                sh 'docker build -t imadtoumi/bl-gr-deployment:latest .'
            }
        }
        
        stage('Docker push to docker hub') {
            steps {
                script{
                    withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                        sh 'docker push imadtoumi/bl-gr-deployment:latest'
                    }
                }
            }
        }
        
        stage('Deploy to kubernetes cluster') {
            steps {
                withKubeCredentials(kubectlCredentials: [[caCertificate: '', clusterName: 'kubernetes', contextName: '', credentialsId: 'k8s-cred', namespace: 'blogging-app', serverUrl: 'https://192.168.1.115:6443']]) {
                    sh 'kubectl apply -f mysql-ds.yml'
                    sh 'kubectl apply -f app-deployment-green.yml'
                    sh 'kubectl apply -f bankapp-service.yml'
                }
            }
        }
        
        stage('Check Deployments') {
            steps {
                withKubeCredentials(kubectlCredentials: [[caCertificate: '', clusterName: 'kubernetes', contextName: '', credentialsId: 'k8s-cred', namespace: 'blogging-app', serverUrl: 'https://192.168.1.115:6443']]) {
                    sh 'kubectl get deployments,svc,pods'
                }
            }
        }
    }
}


