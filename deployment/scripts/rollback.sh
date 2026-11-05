
#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="/opt/mern-ecommerce"
DEPLOYMENT_DIR="${APP_DIR}/deployment"
ENV_FILE="${DEPLOYMENT_DIR}/deployment.env"
BACKUP_FILE="${DEPLOYMENT_DIR}/deployment.env.previous"

cd "${APP_DIR}"

if [[ ! -s "${BACKUP_FILE}" ]]; then
  echo "No previous deployment configuration is available."
  exit 1
fi

echo "Restoring previous image references..."

cp "${BACKUP_FILE}" "${ENV_FILE}"
chmod 600 "${ENV_FILE}"

docker compose \
  --env-file "${ENV_FILE}" \
  -f docker-compose.prod.yml \
  pull

docker compose \
  --env-file "${ENV_FILE}" \
  -f docker-compose.prod.yml \
  up -d --remove-orphans

bash deployment/scripts/health-check.sh

echo "Rollback completed successfully."
