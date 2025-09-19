#!/bin/bash
set -e

cd /actions-runner

if [[ -z "${GH_OWNER}" || -z "${GH_REPO}" || -z "${GH_TOKEN}" ]]; then
  echo "GH_OWNER, GH_REPO, and GH_TOKEN must be set" >&2
  exit 1
fi

echo "Fetching GitHub registration token..."
RUNNER_TOKEN=$(curl -s -X POST \
  -H "Authorization: token ${GH_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/${GH_OWNER}/${GH_REPO}/actions/runners/registration-token \
  | jq -r .token)

if [[ -z "${RUNNER_TOKEN}" || "${RUNNER_TOKEN}" == "null" ]]; then
  echo "Failed to obtain registration token" >&2
  exit 1
fi

echo "Configuring runner..."
./config.sh --url https://github.com/${GH_OWNER}/${GH_REPO} \
            --token "${RUNNER_TOKEN}" \
            --unattended \
            --replace \
            --labels "${RUNNER_LABELS}"

cleanup() {
  echo "Removing runner..."
  ./config.sh remove --token ${RUNNER_TOKEN} || true
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

echo "Starting runner..."
./run.sh


