#!/usr/bin/env bash
# ==============================================================================
# File 01b: Parallel IAM Role Bindings — Option A (WIF) vs. Option B (Cloud Identity Free)
# Compare how Group-based IAM bindings differ between the two Non-GWS Identity options!
# Prerequisite: Custom Role geStandardChatUser created from File 01 (.yaml)
# ==============================================================================
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-YOUR_GCP_PROJECT_ID}"

# ------------------------------------------------------------------------------
# [OPTION A] Workforce Identity Federation (WIF / 3rd Party Identity)
# Uses principalSet://iam.googleapis.com/locations/global/workforcePools/<POOL_ID>/group/<GROUP_ID>
# ------------------------------------------------------------------------------
WIF_POOL_ID="${WIF_POOL_ID:-corp-sso-pool}"
ENTRA_BIZ_GROUP_ID="${ENTRA_BIZ_GROUP_ID:-11111111-2222-3333-4444-555555555555}"
ENTRA_DEV_GROUP_ID="${ENTRA_DEV_GROUP_ID:-aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee}"

echo "=== [Option A: WIF] Granting Web-Only Custom Role & Antigravity Dev Role ==="
# 1) General Employees (GE Web App + Canvas allowed; Antigravity blocked)
# gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
#   --member="principalSet://iam.googleapis.com/locations/global/workforcePools/${WIF_POOL_ID}/group/${ENTRA_BIZ_GROUP_ID}" \
#   --role="projects/${PROJECT_ID}/roles/geStandardChatUser"

# 2) Approved Developers (GE Web App + Google Antigravity IDE/CLI allowed)
# gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
#   --member="principalSet://iam.googleapis.com/locations/global/workforcePools/${WIF_POOL_ID}/group/${ENTRA_DEV_GROUP_ID}" \
#   --role="roles/discoveryengine.agentspaceUser"


# ------------------------------------------------------------------------------
# [OPTION B] Cloud Identity Free (Google Identity — $0 Managed Directory + 3P SSO)
# Uses standard Google Group email: group:<GROUP_EMAIL>
# ------------------------------------------------------------------------------
CI_BIZ_GROUP_EMAIL="${CI_BIZ_GROUP_EMAIL:-ge-business-users@example-corp.com}"
CI_DEV_GROUP_EMAIL="${CI_DEV_GROUP_EMAIL:-ge-antigravity-devs@example-corp.com}"

echo "=== [Option B: Cloud Identity Free] Granting Web-Only Custom Role & Antigravity Dev Role ==="
# 1) General Employees (GE Web App + Canvas allowed; Antigravity blocked)
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="group:${CI_BIZ_GROUP_EMAIL}" \
  --role="projects/${PROJECT_ID}/roles/geStandardChatUser"

# 2) Approved Developers (GE Web App + Google Antigravity IDE/CLI allowed)
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="group:${CI_DEV_GROUP_EMAIL}" \
  --role="roles/discoveryengine.agentspaceUser"
