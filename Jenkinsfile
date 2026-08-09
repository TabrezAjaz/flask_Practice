pipeline {
    agent any

    parameters {
        string(name: 'NOTIFICATION_EMAIL', defaultValue: '', description: 'Address for build notifications (leave blank to skip email)')
    }

    environment {
        STAGING_APP_PATH = 'staging_deploy'
        // Install to the user site and allow pip on externally-managed agents
        PIP_BREAK_SYSTEM_PACKAGES = '1'
    }

    options {
        timestamps()
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Build') {
            steps {
                sh '''
                    python3 -m pip install --user --upgrade pip || true
                    python3 -m pip install --user -r requirements-dev.txt
                    mkdir -p dist
                    tar --exclude=.git --exclude=dist \
                        -czf "dist/flask-app-${BUILD_NUMBER}.tar.gz" .
                '''
            }
        }

        stage('Test') {
            steps {
                sh 'python3 -m pytest -q --junitxml=test-results.xml'
            }
        }

        stage('Deploy to Staging') {
            steps {
                // Staging deployment simulated on the Jenkins workspace: the built
                // artifact is unpacked into the staging path to represent a release.
                sh '''
                    echo "Deploying build ${BUILD_NUMBER} to the staging environment..."
                    rm -rf "$STAGING_APP_PATH"
                    mkdir -p "$STAGING_APP_PATH"
                    tar -xzf "dist/flask-app-${BUILD_NUMBER}.tar.gz" -C "$STAGING_APP_PATH"
                    echo "Application deployed to: $(pwd)/$STAGING_APP_PATH"
                    echo "Staging deployment completed successfully."
                '''
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