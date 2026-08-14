---
description: Generate a structured issue summary for sharing between sessions or teams
template: |
  Generate a comprehensive issue summary based on the current conversation and investigation. Use this exact format:

  ## Issue Summary

  **Service:** [Identify the primary service/component affected]
  **Component:** [Specific module, pod, deployment, or code area]
  **Severity:** [Critical/High/Medium/Low - based on impact]
  **Environment:** [dev/staging/production/local - where the issue occurs]
  **Reporter:** [Current user or "Self" if discovered during work]
  **Date:** [Current date in YYYY-MM-DD format]

  ### Problem Description
  [Clear, concise description of what's wrong. Focus on observable behavior.]

  ### Expected Behavior
  [What should be happening normally]

  ### Actual Behavior
  [What's actually happening - be specific]

  ### Impact
  - **Users Affected:** [Number/percentage of users or "All users" or "Internal only"]
  - **Services Affected:** [List of dependent services impacted]
  - **Business Impact:** [How this affects business operations or user experience]

  ### Context
  - **Related Services:**
    - [Service 1] - [How it's related]
    - [Service 2] - [How it's related]
  - **Recent Changes:**
    - [Deployment/config change 1] - [Timestamp]
    - [Deployment/config change 2] - [Timestamp]
  - **Error Messages:**
    ```
    [Key error messages from logs - redact sensitive info]
    ```
  - **Metrics/Observations:**
    - [Metric 1]: [Value/trend]
    - [Metric 2]: [Value/trend]
  - **Kubernetes/Infrastructure Details:**
    - Namespace: [namespace]
    - Deployment/Pod: [name]
    - Container: [container name]
    - Image: [image:tag]
    - Resource Status: [CrashLoopBackOff/Running/etc]

  ### Investigation Done
  [Summarize what has been checked so far]

  **Logs Examined:**
  - [Pod/service logs checked]
  - [Time range examined]

  **Configuration Verified:**
  - [ConfigMaps checked]
  - [Secrets verified to exist]
  - [Environment variables reviewed]

  **Connectivity Tested:**
  - [Services/endpoints tested]
  - [DNS resolution checked]
  - [Port connectivity verified]

  **Metrics Reviewed:**
  - [What metrics were checked]
  - [What anomalies found]

  **Hypotheses Considered:**
  1. [Hypothesis 1] - [Tested? Result?]
  2. [Hypothesis 2] - [Tested? Result?]
  3. [Hypothesis 3] - [Tested? Result?]

  ### Root Cause
  [If identified: State the root cause clearly]
  [If not yet identified: State "Under investigation" and list most likely causes]

  ### Reproduction Steps
  [If applicable, provide steps to reproduce the issue]
  1. [Step 1]
  2. [Step 2]
  3. [Observe: expected vs actual]

  ### Relevant Files & References
  - [file:line] - [Why relevant]
  - [file:line] - [Why relevant]
  - [Link to dashboard/graph] (if applicable)
  - [Link to related PR/commit] (if applicable)

  ### Proposed Solution
  [If a fix is identified]

  **Immediate Workaround:**
  - [Quick fix to restore service, if available]
  - [Risk level: Low/Medium/High]

  **Permanent Fix:**
  - [Proper long-term solution]
  - [Changes required]
  - [Testing needed]

  **Rollback Plan:**
  - [How to undo the fix if it doesn't work]

  **Prevention:**
  - [How to prevent this in the future]
  - [Monitoring/alerting to add]

  ### Next Steps
  [Ordered list of actions to take]
  1. [Action 1] - [Who should do it]
  2. [Action 2] - [Who should do it]
  3. [Action 3] - [Who should do it]

  ### Questions & Unknowns
  [Things still unclear or needing investigation]
  - [Question 1]
  - [Question 2]

  ### Session Links
  **Current Session:** [Use /share to generate link if needed]
  **Related Sessions:** [Links to other relevant sessions]

  ---

  **Instructions for AI:**
  1. Review the entire conversation history
  2. Extract relevant details from logs, commands, and analysis
  3. Fill in all sections with specific information from the investigation
  4. Be factual and precise - don't speculate without noting it as such
  5. Include specific error messages, metrics, and file references
  6. Redact any sensitive information (API keys, passwords, tokens)
  7. If information is missing for a section, state "Not yet determined" or "Not applicable"
  8. Format the output in clean Markdown
  9. Make it easy to copy/paste to Slack, tickets, or other sessions

  After generating the summary, offer to:
  - Share the current session with /share command
  - Save the summary to a file
  - Copy specific sections for different audiences (technical team, management, etc.)
---
