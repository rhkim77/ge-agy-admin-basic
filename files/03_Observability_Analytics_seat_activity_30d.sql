-- =============================================================================
-- File 03: 30-day activity check before reclaiming a seat
--
-- Where to run: Logging > Observability Analytics, on a _Default log bucket that
-- has been upgraded for Observability Analytics. Replace PROJECT_ID.
--
-- Why two sources: the Manage users export gives last_login_time (the last
-- sign-in). A developer who works only in Antigravity may show little or no
-- Web App activity, so check the Antigravity log as well before reclaiming.
--
-- Field names come from these pages. Query [A] has not been tested against real
-- Antigravity logs. Run the Logs Explorer check first.
--   https://docs.cloud.google.com/gemini/enterprise/docs/ai-developer-tools-track-token-usage
--   https://docs.cloud.google.com/gemini/enterprise/docs/correlate-model-armor-logs
-- =============================================================================

-- [A] Google Antigravity (app, agy CLI, IDE extensions): calls per user, last 30 days.
--     Logs Explorer check first:
--       logName="projects/PROJECT_ID/logs/businessaicode.googleapis.com%2Finference_response"
SELECT
  LOWER(REGEXP_REPLACE(JSON_VALUE(labels.user_id), r'^user:', '')) AS user_email,
  COUNT(*) AS antigravity_calls_30d,
  MAX(timestamp) AS last_antigravity_call
FROM
  `PROJECT_ID.global._Default._Default`
WHERE
  log_id = "businessaicode.googleapis.com/inference_response"
  AND timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND JSON_VALUE(labels.user_id) IS NOT NULL
GROUP BY
  user_email
ORDER BY
  last_antigravity_call ASC;


-- [B] Optional: Gemini Enterprise Web App assistant turns per user, last 30 days.
--     Needs Configurations > Observability turned on for the app.
--     userIamPrincipal is written as "<elided>" unless "Enable logging of prompt
--     inputs and response outputs" is on. That setting also stores prompt and
--     response text, so decide with your security team before enabling it.
--     Without it, use last_login_time from the Manage users export for the
--     Web App side.
SELECT
  LOWER(JSON_VALUE(json_payload.userIamPrincipal)) AS user_principal,
  COUNT(*) AS ge_web_turns_30d,
  MAX(timestamp) AS last_ge_web_turn
FROM
  `PROJECT_ID.global._Default._Default`
WHERE
  log_id = "discoveryengine.googleapis.com/gemini_enterprise_user_activity"
  AND JSON_VALUE(json_payload.logMetadata.methodName) = "StreamAssist"
  AND timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND JSON_VALUE(json_payload.userIamPrincipal) != "<elided>"
GROUP BY
  user_principal
ORDER BY
  last_ge_web_turn ASC;

-- Reclaim rule used in this course:
--   last_login_time (Manage users export) is older than 30 days
--   AND the user does not appear in the result of query [A].
