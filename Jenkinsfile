// Jenkinsfile -- pipeline 10 stages complet
pipeline {
    agent any

    environment {
        IMAGE_NAME = 'sentiment-ai'
        REGISTRY   = 'ghcr.io/aflesec'
        IMAGE_TAG  = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo "Branche : ${env.BRANCH_NAME}"
                echo "Commit : ${env.GIT_COMMIT}"
            }
        }

        stage('Build') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Lint') {
            steps {
                sh "docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} sh -c 'pip install flake8 -q && flake8 src/ --max-line-length=100'"
            }
            post {
                failure {
                    echo 'Lint échoué. Veuillez corriger les erreurs.'
                }
            }
        }

        stage('IaC Validate') {
            steps {
                dir('infra') {
                    sh 'terraform init -backend=false -input=false'
                    sh 'terraform fmt -check'
                    sh 'terraform validate'
                }
            }
        }

        stage('Test') {
            steps {
                sh '''
                docker rm -f test-runner 2>/dev/null || true
                set +e
                docker run \
                  -e CI=true \
                  --name test-runner \
                  ${IMAGE_NAME}:${IMAGE_TAG} \
                  pytest tests/ -v \
                    --cov=src \
                    --cov-report=xml:/tmp/coverage.xml \
                    --cov-report=term-missing \
                    --cov-fail-under=70
                TEST_EXIT_CODE=$?
                set -e

                docker cp test-runner:/tmp/coverage.xml ./coverage.xml 2>/dev/null || true
                docker rm -f test-runner 2>/dev/null || true

                exit $TEST_EXIT_CODE
                '''
            }
            post {
                failure {
                    echo 'Tests échoués ou coverage insuffisant (< 70%).'
                }
            }
        }

        stage('Security Scan') {
            steps {
                sh '''
                docker run --rm \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  -v trivy-cache:/root/.cache/trivy \
                  aquasec/trivy:latest image \
                    --severity HIGH,CRITICAL \
                    --ignore-unfixed \
                    --exit-code 1 \
                    --format table \
                    ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
            post {
                failure {
                    echo 'Vulnérabilités CRITICAL ou HIGH (corrigeables) détectées !'
                }
            }
        }
        stage('SonarQube Analysis') {
            environment {
                SONARQUBE_TOKEN = credentials('sonar-token')
            }
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh '''
                    docker run --rm \
                      --network cicd-network \
                      --volumes-from jenkins \
                      -w "$WORKSPACE" \
                      -e SONAR_HOST_URL="$SONAR_HOST_URL" \
                      -e SONAR_TOKEN="$SONARQUBE_TOKEN" \
                      sonarsource/sonar-scanner-cli:latest \
                      sonar-scanner \
                        -Dsonar.projectKey=sentiment-ai \
                        -Dsonar.sources=src \
                        -Dsonar.python.coverage.reportPaths=coverage.xml \
                        -Dsonar.working.directory="$WORKSPACE/.scannerwork" \
                        -Dsonar.scanner.metadataFilePath="$WORKSPACE/.scannerwork/report-task.txt"
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Push') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-token',
                        usernameVariable: 'REGISTRY_USER',
                        passwordVariable: 'REGISTRY_PASS'
                    )
                ]) {
                    sh """
                    echo \$REGISTRY_PASS | docker login ghcr.io -u \$REGISTRY_USER --password-stdin
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:latest
                    docker push ${REGISTRY}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        // IaC Apply -- main seulement, après Push
        stage('IaC Apply') {
            when {
                branch 'main'
            }
            steps {
                dir('infra') {
                    sh 'terraform init -input=false'
                    sh "terraform apply -auto-approve -var='image_tag=${IMAGE_TAG}'"
                }
            }
        }

        stage('Deploy Staging') {
            when {
                branch 'main'
            }
            steps {
                sh 'curl -f http://sentiment-staging:8000/health || exit 1'
            }
        }

        stage('Smoke Test') {
    when {
        branch 'main'
    }
    steps {
        sh '''
        echo "Attente démarrage (10s)..."
        sleep 10

        # 1. L'app répond
        curl -f http://sentiment-staging:8000/health || exit 1
        echo "/health OK"

        # 2. Les métriques sont exposées
        curl -s http://sentiment-staging:8000/metrics | grep -q sentiment_predictions_total || exit 1
        echo "/metrics OK -- métriques SentimentAI présentes"

        # 3. Prometheus scrape l'app
        sleep 20   # attendre au moins 1 scrape (15s)
        curl -s "http://prometheus:9090/api/v1/query?query=up{job='sentiment-ai'}" | grep -q '"value":.*1' || exit 1
        echo "Prometheus scrape sentiment-ai : UP"

        # 4. Grafana répond
        curl -f http://grafana:3000/api/health || exit 1
        echo "Grafana OK"
        '''
    }
    post {
        failure {
            sh 'docker logs prometheus || true'
            sh 'docker logs sentiment-staging || true'
            echo 'Smoke Test KO -- voir logs ci-dessus'
        }
    }
}

    }

    post {
        always {
            sh 'docker compose down -v 2>/dev/null || true'
        }
        success {
            echo "Pipeline OK -- ${IMAGE_TAG} déployé"
        }
        failure {
            echo 'Pipeline KO'
        }
    }
}