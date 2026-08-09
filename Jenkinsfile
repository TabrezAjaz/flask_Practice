pipeline {
    agent any

    parameters {
        string(name: 'NOTIFICATION_EMAIL', defaultValue: '', description: 'Address for build notifications')
    }

    environment {
        VENV = '.venv'
        STAGING_HOST = credentials('staging-host')
        STAGING_APP_PATH = '/opt/student-registration'
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Build') {
            steps {
                sh '''
                    python3 -m venv "$VENV"
                    "$VENV/bin/python" -m pip install --upgrade pip
                    "$VENV/bin/pip" install -r requirements-dev.txt
                    mkdir -p dist
                    tar --exclude=.git --exclude=.venv --exclude=dist \
                        -czf dist/student-registration.tar.gz .
                '''
            }
        }

        stage('Test') {
            steps {
                sh '"$VENV/bin/python" -m pytest -q --junitxml=test-results.xml'
            }
        }

        stage('Deploy to Staging') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'staging-ssh',
                    keyFileVariable: 'SSH_KEY',
                    usernameVariable: 'SSH_USER'
                )]) {
                    sh 'bash ./scripts/deploy.sh staging "$STAGING_HOST" "$SSH_USER" "$STAGING_APP_PATH" "$SSH_KEY" "$BUILD_NUMBER"'
                }
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true, testResults: 'test-results.xml'
            archiveArtifacts allowEmptyArchive: true, artifacts: 'dist/*.tar.gz', fingerprint: true
        }
        success {
            script {
                if (params.NOTIFICATION_EMAIL?.trim()) {
                    emailext(
                        to: params.NOTIFICATION_EMAIL,
                        subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: "Build, tests, and staging deployment succeeded.\n${env.BUILD_URL}"
                    )
                }
            }
        }
        failure {
            script {
                if (params.NOTIFICATION_EMAIL?.trim()) {
                    emailext(
                        to: params.NOTIFICATION_EMAIL,
                        subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: "The pipeline failed. Review the Jenkins console output:\n${env.BUILD_URL}"
                    )
                }
            }
        }
    }
}