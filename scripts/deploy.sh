#!/usr/bin/env bash
set -euo pipefail

environment_name=${1:?Usage: deploy.sh ENV HOST USER APP_PATH KEY_FILE RELEASE_ID}
deploy_host=${2:?Missing deployment host}
deploy_user=${3:?Missing deployment user}
app_path=${4:?Missing application path}
key_file=${5:?Missing SSH private key file}
release_id=${6:?Missing release identifier}
artifact="dist/student-registration.tar.gz"
remote_artifact="/tmp/student-registration-${release_id}.tar.gz"

test -f "$artifact"
ssh_options=(-i "$key_file" -o BatchMode=yes -o StrictHostKeyChecking=accept-new)

echo "Deploying release ${release_id} to ${environment_name}"
scp "${ssh_options[@]}" "$artifact" "${deploy_user}@${deploy_host}:${remote_artifact}"
ssh "${ssh_options[@]}" "${deploy_user}@${deploy_host}" \
  "APP_PATH='$app_path' RELEASE_ID='$release_id' ARTIFACT='$remote_artifact' bash -s" <<'REMOTE_SCRIPT'
set -euo pipefail
release_path="$APP_PATH/releases/$RELEASE_ID"
mkdir -p "$release_path"
tar -xzf "$ARTIFACT" -C "$release_path"
python3 -m venv "$release_path/.venv"
"$release_path/.venv/bin/pip" install --quiet --upgrade pip
"$release_path/.venv/bin/pip" install --quiet -r "$release_path/requirements.txt"
ln -sfn "$release_path" "$APP_PATH/current"
sudo systemctl restart student-registration
curl --fail --retry 5 --retry-delay 2 http://127.0.0.1:8000/health
rm -f "$ARTIFACT"
REMOTE_SCRIPT