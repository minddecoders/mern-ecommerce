
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

TEMP_ENV="$(mktemp "${DEPLOYMENT_DIR}/deployment.env.rollback.XXXXXX")"
cp "${BACKUP_FILE}" "${TEMP_ENV}"
chmod 600 "${TEMP_ENV}"
mv "${TEMP_ENV}" "${ENV_FILE}"

echo "Pulling previous images..."

docker compose \
  --env-file "${ENV_FILE}" \
  -f docker-compose.prod.yml \
  pull

echo "Starting previous application..."

docker compose \
  --env-file "${ENV_FILE}" \
  -f docker-compose.prod.yml \
  up -d --remove-orphans

bash deployment/scripts/health-check.sh

echo "Rollback completed successfully."
