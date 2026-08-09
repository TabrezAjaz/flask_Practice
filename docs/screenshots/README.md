# CI/CD Screenshot Evidence Checklist

Add real screenshots using these exact names so the evidence remains easy to review.

## Jenkins

1. `jenkins/01-jenkins-dashboard.png` - Jenkins running with the pipeline job visible.
2. `jenkins/02-pipeline-stages-success.png` - Build, Test, and Deploy to Staging all green.
3. `jenkins/03-pytest-console-output.png` - Console output showing all tests passed.
4. `jenkins/04-webhook-configuration.png` - GitHub webhook with a successful delivery.
5. `jenkins/05-email-notification.png` - Success email with job name and build number.

## GitHub Actions

1. `github-actions/01-main-ci-success.png` - Main branch Test and Build job succeeded.
2. `github-actions/02-staging-deployment.png` - Staging deployment job succeeded.
3. `github-actions/03-production-tag-deployment.png` - Production deployment from a `v*` tag.
4. `github-actions/04-environments.png` - Staging and production environments (secret values hidden).
5. `github-actions/05-workflow-summary.png` - Workflow graph showing completed jobs.

Keep secrets, private keys, tokens, MongoDB passwords, and Jenkins initial passwords out of every
screenshot. Crop only irrelevant browser chrome; retain the repository/job name, run number, and
green status so each image is useful evidence.