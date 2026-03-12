name: Bug Report Triage Pipeline

# 1. The Trigger: What causes this workflow to run?
on:
  issues:
    types: [opened, labeled]

jobs:
  diagnostics-and-testing:
    # 2. The Filter: Only run if the issue has the 'bug' label
    if: contains(github.event.issue.labels.*.name, 'bug')
    runs-on: ubuntu-latest

    steps:
      # 3. The Actions: What should happen?
      - name: Checkout repository code
        uses: actions/checkout@v4

      # (Example) Set up the environment needed for your tests
      - name: Set up testing environment (Node.js example)
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      # (Example) Run your actual test script
      - name: Run automated diagnostics/tests
        run: |
          echo "Running test suite against the main branch..."
          # Replace this with your actual test command, e.g., npm test, pytest, etc.
          echo "Tests completed."

      # Automatically comment on the issue to keep the reporter informed
      - name: Notify user on the issue
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '🚀 **Automated Response:** Thank you for the bug report! We have automatically triggered our diagnostic pipelines against the main branch. A maintainer will review the results shortly.'
            })
