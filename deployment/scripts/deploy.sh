
#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="/opt/mern-ecommerce"
DEPLOYMENT_DIR="${APP_DIR}/deployment"
ENV_FILE="${DEPLOYMENT_DIR}/deployment.env"
BACKUP_FILE="${DEPLOYMENT_DIR}/deployment.env.previous"
PRODUCTION_ENV="${DEPLOYMENT_DIR}/.env.production"

AWS_REGION="eu-west-1"
AWS_ACCOUNT_ID="951614974272"
PARAMETER_NAME="/mern-learning/production/env"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

IMAGE_TAG="${1:?Usage: deploy.sh <40-character-commit-sha>}"

if [[ ! "${IMAGE_TAG}" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Invalid commit SHA: ${IMAGE_TAG}"
  exit 1
fi

cd "${APP_DIR}"
mkdir -p "${DEPLOYMENT_DIR}"

echo "Retrieving production environment from Parameter Store..."

aws ssm get-parameter \
  --name "${PARAMETER_NAME}" \
  --with-decryption \
  --region "${AWS_REGION}" \
  --query 'Parameter.Value' \
  --output text > "${PRODUCTION_ENV}"

chmod 600 "${PRODUCTION_ENV}"

if ! grep -q '^JWT_SECRET=.' "${PRODUCTION_ENV}"; then
  echo "JWT_SECRET is missing or empty."
  exit 1
fi

if ! grep -q '^MONGO_URI=.' "${PRODUCTION_ENV}"; then
  echo "MONGO_URI is missing or empty."
  exit 1
fi

HAD_PREVIOUS_DEPLOYMENT=false

if [[ -s "${ENV_FILE}" ]]; then
  cp "${ENV_FILE}" "${BACKUP_FILE}"
  HAD_PREVIOUS_DEPLOYMENT=true
fi

echo "Authenticating with ECR..."

aws ecr get-login-password --region "${AWS_REGION}" |
  docker login \
    --username AWS \
    --password-stdin "${ECR_REGISTRY}"

TEMP_ENV="$(mktemp "${DEPLOYMENT_DIR}/deployment.env.XXXXXX")"

cat > "${TEMP_ENV}" <<EOF
AWS_REGION=${AWS_REGION}
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}
ECR_CLIENT_IMAGE=${ECR_REGISTRY}/mern-learning-client:release-${IMAGE_TAG}
ECR_SERVER_IMAGE=${ECR_REGISTRY}/mern-learning-server:release-${IMAGE_TAG}
EOF

chmod 600 "${TEMP_ENV}"

# Pull images before changing the active deployment configuration.
echo "Pulling application images..."

if ! docker compose \
  --env-file "${TEMP_ENV}" \
  -f docker-compose.prod.yml \
  pull; then
  echo "Image pull failed. Existing deployment remains unchanged."
  rm -f "${TEMP_ENV}"
  exit 1
fi

# Activate the new image configuration.
mv "${TEMP_ENV}" "${ENV_FILE}"

echo "Starting application..."

if docker compose \
  --env-file "${ENV_FILE}" \
  -f docker-compose.prod.yml \
  up -d --remove-orphans &&
  bash deployment/scripts/health-check.sh; then

  echo "Deployment ${IMAGE_TAG} succeeded."
  exit 0
fi

echo "Deployment failed."

if [[ "${HAD_PREVIOUS_DEPLOYMENT}" == "true" ]]; then
  echo "Attempting rollback..."

  if bash deployment/scripts/rollback.sh; then
    echo "Previous deployment restored."
  else
    echo "Rollback failed. Inspect Docker Compose logs."
  fi
else
  echo "No previous deployment exists. Stopping failed containers..."

  docker compose \
    --env-file "${ENV_FILE}" \
    -f docker-compose.prod.yml \
    down || true
fi

exit 1
