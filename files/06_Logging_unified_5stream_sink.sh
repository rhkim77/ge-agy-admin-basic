#!/usr/bin/env bash
# ==============================================================================
# File 06: One log sink for the five Gemini Enterprise and Antigravity log streams
#   1) discoveryengine.googleapis.com/gemini_enterprise_user_activity
#   2) discoveryengine.googleapis.com/notebooklm_enterprise_user_activity
#   3) businessaicode.googleapis.com/inference_response (Google Antigravity)
#   4) cloudaudit.googleapis.com (Admin Activity and Data Access audit logs)
#   5) modelarmor.googleapis.com/SanitizeOperation
# Destination: a Pub/Sub topic that an external SIEM reads with a pull
# subscription, so no inbound firewall rule is needed.
# The SQL in File 03 does not use this sink. It reads the _Default log bucket
# through Observability Analytics.
# ==============================================================================
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-YOUR_GCP_PROJECT_ID}"
PUBSUB_TOPIC="${PUBSUB_TOPIC:-ge-security-siem-topic}"
SINK_NAME="${SINK_NAME:-ge-antigravity-unified-sink}"

LOG_FILTER='logName:("gemini_enterprise_user_activity" OR "notebooklm_enterprise_user_activity" OR "businessaicode.googleapis.com%2Finference_response" OR "cloudaudit.googleapis.com") OR resource.type="modelarmor.googleapis.com/SanitizeOperation"'

echo "[1/3] Creating the Pub/Sub topic..."
gcloud pubsub topics create "${PUBSUB_TOPIC}" --project="${PROJECT_ID}" || true

echo "[2/3] Creating the log sink..."
gcloud logging sinks create "${SINK_NAME}" \
  "pubsub.googleapis.com/projects/${PROJECT_ID}/topics/${PUBSUB_TOPIC}" \
  --project="${PROJECT_ID}" \
  --log-filter="${LOG_FILTER}"

echo "[3/3] Letting the sink's writer identity publish to the topic..."
WRITER_IDENTITY="$(gcloud logging sinks describe "${SINK_NAME}" --project="${PROJECT_ID}" --format='value(writerIdentity)')"
gcloud pubsub topics add-iam-policy-binding "${PUBSUB_TOPIC}" \
  --project="${PROJECT_ID}" \
  --member="${WRITER_IDENTITY}" \
  --role="roles/pubsub.publisher"
