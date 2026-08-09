# Flask Student Registration - Jenkins and GitHub Actions CI/CD

HeroVired DevOps assignment implementing two complete CI/CD pipelines for the provided
[Flask practice application](https://github.com/mohanDevOps-arch/flask_Practice):

- Jenkins: build, test, deploy to staging, and email notification.
- GitHub Actions: test/build on `main` and `staging`, staging deployment from the
  `staging` branch, and production deployment from `v*` release tags.

The print-ready submission is [CI_CD_Pipeline_Assignment_Report.html](CI_CD_Pipeline_Assignment_Report.html).

## Pipeline Design

```text
Developer push
     |
     +-- main ------> Jenkins webhook --> Build --> Test --> Staging deploy --> Email
     |
     +-- main ------> GitHub Actions ----> Test + Build artifact
     |
     +-- staging ---> GitHub Actions ----> Test + Build --> Staging deploy
     |
     +-- v1.0.0 ----> GitHub Actions ----> Test + Build --> Production deploy
```

Both systems execute the same `pytest` suite and create the same compressed release artifact.
Deployment uses SSH, installs runtime dependencies into a release-specific virtual environment,
switches an atomic `current` symlink, restarts systemd, and verifies `GET /health`.

## Repository Contents

| Path | Purpose |
|---|---|
| `app.py` | Flask/MongoDB student registration application and health endpoint |
| `test_app.py` | Five isolated tests using an in-memory MongoDB replacement |
| `Jenkinsfile` | Declarative Jenkins build, test, staging deploy, and email pipeline |
| `.github/workflows/cicd.yml` | GitHub Actions CI, staging CD, and production CD |
| `scripts/deploy.sh` | Shared SSH release deployment and health verification |
| `scripts/install-service.sh` | One-time systemd service installation on a deployment VM |
| `requirements.txt` | Runtime dependencies |
| `requirements-dev.txt` | Test and quality-tool dependencies |
| `docs/screenshots/` | Required real execution evidence checklist |

## Local Setup and Test

Prerequisites: Python 3.10 or newer and MongoDB for normal application use. Tests do not
require a running MongoDB instance.

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate
# Linux/macOS: source .venv/bin/activate
pip install -r requirements-dev.txt
pytest -q
```

Expected result: `5 passed`.

For normal use, copy `.env.example` to `.env`, set `MONGO_URI` and `SECRET_KEY`, then run:

```bash
python app.py
```

The application is available at `http://localhost:5000`; health is at `/health`.

## Deployment Server Prerequisites

Use separate Ubuntu VMs for staging and production, or separate hosts with equivalent
isolation. Install Python, create a deployment user, and configure the service once:

```bash
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl
git clone <your-fork-url> flask-cicd
cd flask-cicd
bash scripts/install-service.sh /opt/student-registration "$USER"
sudo sh -c 'printf "%s\n" \
  "MONGO_URI=mongodb+srv://USER:PASSWORD@HOST/student_db" \
  "SECRET_KEY=REPLACE_WITH_RANDOM_VALUE" > /etc/student-registration.env'
sudo chmod 600 /etc/student-registration.env
```

Permit the deployment user to restart only this service with `sudo visudo`:

```text
DEPLOY_USER ALL=(root) NOPASSWD: /bin/systemctl restart student-registration
```

The server must accept the CI public key in `~/.ssh/authorized_keys`. Keep MongoDB credentials
only on the server; they are not copied into either pipeline.

## Jenkins Setup

### 1. Install Jenkins and Python on Ubuntu

```bash
sudo apt-get update
sudo apt-get install -y fontconfig openjdk-21-jre python3 python3-venv git curl
sudo mkdir -p /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list >/dev/null
sudo apt-get update
sudo apt-get install -y jenkins
sudo systemctl enable --now jenkins
```

Open `http://JENKINS_HOST:8080` and install Suggested Plugins plus **Email Extension**,
**JUnit**, **GitHub Integration**, and **Credentials Binding**.

### 2. Add Jenkins credentials

In **Manage Jenkins > Credentials > System > Global credentials**, add:

| ID | Kind | Value |
|---|---|---|
| `staging-host` | Secret text | Staging VM hostname or public IP |
| `staging-ssh` | SSH username with private key | Deployment user and private key |

Configure SMTP under **Manage Jenkins > System > Extended E-mail Notification**. Supply the
recipient using the job's `NOTIFICATION_EMAIL` parameter.

### 3. Create the pipeline and webhook

1. Select **New Item > Pipeline** and name it `flask-student-cicd`.
2. Choose **Pipeline script from SCM**, Git, enter the fork URL, branch `*/main`, and script
   path `Jenkinsfile`.
3. In GitHub, open **Settings > Webhooks > Add webhook**.
4. Set Payload URL to `http://JENKINS_HOST:8080/github-webhook/`, content type
   `application/json`, and select push events.
5. Push a commit to `main`; Jenkins should display Build, Test, and Deploy to Staging.

The `post` section publishes JUnit results and the artifact, then sends success or failure email.

## GitHub Actions Setup

### 1. Create required branches

```bash
git checkout -b staging
git push -u origin staging
git checkout main
```

### 2. Configure environments

In **Settings > Environments**, create both `staging` and `production`. Add these to each:

| Type | Name | Meaning |
|---|---|---|
| Secret | `DEPLOY_HOST` | VM hostname or public IP |
| Secret | `DEPLOY_USER` | SSH deployment username |
| Secret | `SSH_PRIVATE_KEY` | Private key whose public key is authorized on the VM |
| Variable | `APP_PATH` | `/opt/student-registration` |
| Variable | `APP_URL` | Public environment URL shown in the Actions deployment |

GitHub encrypts secrets and does not expose them in workflow logs. Add a required reviewer to
the `production` environment when the account plan supports deployment protection rules.

### 3. Exercise all workflow paths

```bash
# CI on main
git push origin main

# Staging deployment
git checkout staging
git merge main
git push origin staging

# Production deployment from a release tag
git checkout main
git tag -a v1.0.0 -m "Production release v1.0.0"
git push origin v1.0.0
```

## Evidence and Submission

Capture the real Jenkins and GitHub run screens listed in
[docs/screenshots/README.md](docs/screenshots/README.md). Do not use mock screenshots. After
adding them, open the HTML report in a browser, print it to PDF if Vlearn requires PDF, and submit
the repository URL stored in `GitHub Repository Link - CI CD Pipeline.txt`.

## Security Notes

- `.env`, virtual environments, artifacts, and test reports are ignored by Git.
- Deployment keys and host details are held in Jenkins credentials or GitHub environment secrets.
- Production is tag-gated and can also be protected with environment approval.
- The deployment endpoint is verified after every release; a failed health check fails the job.
- Rotate any credential immediately if it is accidentally printed or committed.

## Current Verification

- Local tests: **5 passed** on 7 August 2026.
- Workflow YAML: parsed successfully.
- Deployment scripts: Bash syntax check passed.
- Jenkins/GitHub cloud runs: require your fork, credentials, and deployment VMs; capture these
  real runs before final Vlearn submission.

**Submitted by:** Tabrez Ajaz