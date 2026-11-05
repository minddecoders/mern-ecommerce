
#!/usr/bin/env bash
set -Eeuo pipefail

APP_URL="${1:-http://127.0.0.1}"

echo "Checking application at ${APP_URL}"

for attempt in $(seq 1 30); do
  if curl --fail --silent --show-error \
    --max-time 5 \
    "${APP_URL}/" >/dev/null 2>&1; then
    echo "Application health check passed."
    exit 0
  fi

  echo "Health check attempt ${attempt}/30 failed. Waiting..."
  sleep 5
done

echo "Application did not become healthy."
exit 1
