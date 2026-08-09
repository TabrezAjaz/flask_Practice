#!/usr/bin/env bash
set -euo pipefail

app_path=${1:-/opt/student-registration}
service_user=${2:-$USER}

sudo mkdir -p "$app_path/releases"
sudo chown -R "$service_user:$service_user" "$app_path"

sudo tee /etc/systemd/system/student-registration.service >/dev/null <<EOF
[Unit]
Description=Student Registration Flask Application
After=network.target

[Service]
User=$service_user
WorkingDirectory=$app_path/current
EnvironmentFile=/etc/student-registration.env
ExecStart=$app_path/current/.venv/bin/gunicorn --workers 2 --bind 127.0.0.1:8000 app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable student-registration
echo "Create /etc/student-registration.env with MONGO_URI and SECRET_KEY before the first deployment."