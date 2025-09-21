#!/bin/bash
set -e

cd /actions-runner

if [[ -z "${GH_OWNER}" || -z "${GH_REPO}" || -z "${GITHUB_RUNNER_PAT}" ]]; then
  echo "GH_OWNER, GH_REPO, and GITHUB_RUNNER_PAT must be set" >&2
  exit 1
fi

# Generate a unique name for this runner based on ECS task ID
TASK_ID=""
if [ -n "$ECS_CONTAINER_METADATA_URI_V4" ]; then
  echo "Fetching ECS task metadata..."
  TASK_METADATA=$(curl -s ${ECS_CONTAINER_METADATA_URI_V4}/task)
  TASK_ID=$(echo $TASK_METADATA | jq -r '.TaskARN' | awk -F '/' '{print $NF}' || echo "")
  echo "ECS Task ID: ${TASK_ID}"
fi

# If we couldn't get the task ID, fallback to hostname
if [ -z "$TASK_ID" ]; then
  TASK_ID=$(hostname)
  echo "Using hostname as fallback: ${TASK_ID}"
fi

RUNNER_NAME="runner-${GH_REPO}-${TASK_ID}"
echo "Using runner name: ${RUNNER_NAME}"

echo "Fetching GitHub registration token..."
RESPONSE=$(curl -s -X POST \
  -H "Authorization: token ${GITHUB_RUNNER_PAT}" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/${GH_OWNER}/${GH_REPO}/actions/runners/registration-token)

RUNNER_TOKEN=$(echo "$RESPONSE" | jq -r .token)

if [[ -z "${RUNNER_TOKEN}" || "${RUNNER_TOKEN}" == "null" ]]; then
  echo "ERROR: Failed to obtain registration token" >&2
  echo "GitHub API response: $RESPONSE"
  exit 1
fi

echo "Configuring ephemeral runner..."
./config.sh \
  --url https://github.com/${GH_OWNER}/${GH_REPO} \
  --token "${RUNNER_TOKEN}" \
  --unattended \
  --ephemeral \
  --name "${RUNNER_NAME}" \
  --labels "${RUNNER_LABELS}" \
  --disableupdate

# Disable auto-update
if [ -d ".runner" ]; then
  echo "Creating .disableupdate file to prevent auto-updates..."
  touch .runner/.disableupdate
fi

echo "Starting ephemeral runner..."
./run.sh

echo "Runner has finished its job. Exiting..."
exit 0
