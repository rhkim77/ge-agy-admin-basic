#!/usr/bin/env bash
# ==============================================================================
# File 04: Web App security prerequisites (Sensitive Data Protection + Model Armor)
#   1) Enables the DLP and Model Armor APIs
#   2) Grants roles/dlp.user to the Discovery Engine service agent. The content
#      policy page lists this role as a prerequisite, so grant it before you
#      attach a policy.
#      https://docs.cloud.google.com/gemini/enterprise/docs/protect-sensitive-data
#   3) Creates the template for user prompts in the us multi-region. A global
#      app uses a us or eu Model Armor template.
#      https://docs.cloud.google.com/gemini/enterprise/docs/enable-model-armor
# Create the template for responses the same way, without the prompt injection
# and jailbreak filter, then attach both in Configurations > Assistant.
# ==============================================================================
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-YOUR_GCP_PROJECT_ID}"
PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"
TOKEN="$(gcloud auth print-access-token)"

echo "[1/3] Enabling the DLP and Model Armor APIs..."
gcloud services enable dlp.googleapis.com modelarmor.googleapis.com --project="${PROJECT_ID}"

echo "[2/3] Granting roles/dlp.user to the Discovery Engine service agent..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-discoveryengine.iam.gserviceaccount.com" \
  --role="roles/dlp.user"

echo "[3/3] Creating the Model Armor template for user prompts in locations/us..."
curl -sS -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  -H "Content-Type: application/json" \
  "https://modelarmor.us.rep.googleapis.com/v1/projects/${PROJECT_ID}/locations/us/templates?templateId=ge-prod-input-guard" \
  -d '{
    "filterConfig": {
      "piAndJailbreakFilterSettings": {
        "filterEnforcement": "ENABLED",
        "confidenceLevel": "MEDIUM_AND_ABOVE"
      },
      "maliciousUriFilterSettings": {
        "filterEnforcement": "ENABLED"
      }
    },
    "templateMetadata": {
      "logSanitizeOperations": true,
      "logTemplateOperations": true
    }
  }' | python3 -m json.tool
