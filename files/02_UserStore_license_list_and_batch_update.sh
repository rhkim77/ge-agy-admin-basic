#!/usr/bin/env bash
# ==============================================================================
# File 02: Discovery Engine UserStore REST API — List & Batch Assign/Reclaim
# Target Environment: Non-GWS Enterprise (Gemini Enterprise + Google Antigravity)
# Prerequisite IAM on HR Sync Service Account: roles/discoveryengine.admin
# ==============================================================================
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-YOUR_GCP_PROJECT_ID}"
PROJECT_NUMBER="${PROJECT_NUMBER:-YOUR_PROJECT_NUMBER}"
LOCATION="${LOCATION:-global}"
LICENSE_CONFIG_ID="${LICENSE_CONFIG_ID:-YOUR_LICENSE_CONFIG_ID}"

BASE_URL="https://discoveryengine.googleapis.com"
if [[ "${LOCATION}" != "global" ]]; then
  BASE_URL="https://${LOCATION}-discoveryengine.googleapis.com"
fi

TOKEN="$(gcloud auth print-access-token)"

echo "=== [1] List All User Licenses & Last Login Timestamps (userLicenses.list) ==="
curl -sS -X GET \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "${BASE_URL}/v1/projects/${PROJECT_ID}/locations/${LOCATION}/userStores/default_user_store/userLicenses?pageSize=1000" \
  | python3 -m json.tool

# Uncomment below to execute batch assignment + dormant/leaver reclamation:
# echo "=== [2] Batch Assign Joiners & Reclaim Dormant/Leaver Seats (batchUpdateUserLicenses) ==="
# curl -sS -X POST \
#   -H "Authorization: Bearer ${TOKEN}" \
#   -H "X-Goog-User-Project: ${PROJECT_ID}" \
#   -H "Content-Type: application/json" \
#   "${BASE_URL}/v1/projects/${PROJECT_ID}/locations/${LOCATION}/userStores/default_user_store:batchUpdateUserLicenses" \
#   -d "{
#     \"inlineSource\": {
#       \"userLicenses\": [
#         {
#           \"userPrincipal\": \"new_joiner@example-corp.com\",
#           \"licenseConfig\": \"projects/${PROJECT_NUMBER}/locations/${LOCATION}/licenseConfigs/${LICENSE_CONFIG_ID}\"
#         },
#         {
#           \"userPrincipal\": \"dormant_or_leaver@example-corp.com\"
#         }
#       ],
#       \"updateMask\": \"userPrincipal,licenseConfig\"
#     },
#     \"deleteUnassignedUserLicenses\": true
#   }" | python3 -m json.tool
