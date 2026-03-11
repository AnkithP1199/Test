#!/usr/bin/env bash
# create_files.sh
# Creates the iOS sample app files, GitHub templates, CI/CD workflows, fastlane config,
# and helper scripts in the current git repository. Optionally commits and pushes to
# the branch feature/add-ios-sample-ci and can open a PR using gh CLI.
#
# Usage:
#   chmod +x create_files.sh
#   ./create_files.sh
#
# Notes:
# - This script will overwrite files with the same paths.
# - No secrets are written by this script.
# - After creating files you will be prompted whether to commit/push and optionally open a PR.
set -euo pipefail

BRANCH="${BRANCH:-feature/add-ios-sample-ci}"
REMOTE="${REMOTE:-origin}"
PR_TITLE="Add iOS sample app, CI/CD, Fastlane (match), and project board"
PR_BODY_FILE="PR_DESCRIPTION.md"

# Ensure we are in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: this script must be run from the root of a git repository."
  exit 1
fi

echo "Creating files for iOS sample app and CI/CD..."

# Create directories
mkdir -p Sources/TestApp
mkdir -p Tests/TestAppTests
mkdir -p .github/ISSUE_TEMPLATE
mkdir -p .github/workflows
mkdir -p fastlane
mkdir -p scripts

# README.md
cat > README.md <<'EOF'
# TestApp (Sample iOS project)

This repository contains a minimal sample iOS SwiftUI app (TestApp) plus GitHub configuration
for the PM → Dev → CI → QA → CD workflow.

What's included
- A minimal SwiftUI app source (Sources/TestApp)
- Xcode project specification (project.yml) for xcodegen generation
- GitHub Issue templates and PR template
- GitHub Actions workflows for CI and CD (CI builds/tests; CD uses Fastlane + match to upload to TestFlight)
- Fastlane setup (Fastfile, Gemfile)
- Project board creation script (scripts/create_project_board.sh)

Setup
1. Install xcodegen (https://github.com/yonaskolb/XcodeGen) and generate the Xcode project:
   brew install xcodegen
   xcodegen generate

2. Install Ruby gems (fastlane) if you plan to use the CD pipeline:
   bundle install --gemfile=fastlane/Gemfile

3. Add repository secrets in GitHub (see .github/SECRETS.md).

Run CI locally
- You can run xcodebuild against the generated TestApp.xcodeproj and run tests.

Contributing
- Branch naming: feature/<issue#>-short-desc, bugfix/<issue#>-short-desc
- Use the issue and PR templates in .github
EOF

# project.yml (xcodegen)
cat > project.yml <<'EOF'
name: TestApp
options:
  bundleIdPrefix: com.ankithp1199
configs:
  Debug: debug
  Release: release
settings:
  PRODUCT_BUNDLE_IDENTIFIER: com.ankithp1199.TestApp
  IPHONEOS_DEPLOYMENT_TARGET: "17.0"
targets:
  TestApp:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: Sources/TestApp
    settings:
      INFO_PLIST_FILE: Info.plist
schemes:
  TestApp:
    build:
      targets:
        - TestApp
EOF

# SwiftUI App entry
cat > Sources/TestApp/TestAppApp.swift <<'EOF'
import SwiftUI

@main
struct TestAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
EOF

# ContentView
cat > Sources/TestApp/ContentView.swift <<'EOF'
import SwiftUI

struct ContentView: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("TestApp")
                .font(.largeTitle)
                .bold()

            Text("Counter: \(count)")
                .font(.title2)

            Button(action: { count += 1 }) {
                Text("Increment")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
EOF

# Minimal Info.plist
cat > Sources/TestApp/Info.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>TestApp</string>
  <key>CFBundleIdentifier</key>
  <string>com.ankithp1199.TestApp</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>UILaunchStoryboardName</key>
  <string>LaunchScreen</string>
  <key>LSRequiresIPhoneOS</key>
  <true/>
  <key>UIDeviceFamily</key>
  <array>
    <integer>1</integer>
    <integer>2</integer>
  </array>
</dict>
</plist>
EOF

# Unit test
cat > Tests/TestAppTests/TestAppTests.swift <<'EOF'
import XCTest
@testable import TestApp

final class TestAppTests: XCTestCase {
    func testExample() throws {
        XCTAssertEqual(1 + 1, 2)
    }
}
EOF

# Issue templates
cat > .github/ISSUE_TEMPLATE/bug_report.md <<'EOF'
---
name: Bug report
about: Create a report to help us improve
title: "[BUG] <short description>"
labels: bug, needs-triage
assignees: ''
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots / Logs**
If applicable, add screenshots or paste relevant logs.

**Device & OS (please complete the following information):**
 - Device: iPhone 13, Simulator iPhone 14
 - OS: iOS 17.0

**Steps to fix (optional)**
If you have an idea how to fix it, describe here.

**Acceptance Criteria**
- Fix validated on TestFlight / device
- Unit/UI tests added (if applicable)
EOF

cat > .github/ISSUE_TEMPLATE/feature_request.md <<'EOF'
---
name: Feature request / Story
about: Suggest an idea or create a story for work
title: "[STORY] <short description>"
labels: story
assignees: ''

---

**User story**
As a <role>, I want <feature> so that <benefit>.

**Acceptance criteria**
- Criteria 1
- Criteria 2

**Notes**
- UI/Design links, mockups, API notes, etc.
EOF

# Pull request template
cat > .github/PULL_REQUEST_TEMPLATE.md <<'EOF'
## Summary
<!-- Short description of what this PR does -->

## Related Issue
Closes #<issue-number>

## Checklist
- [ ] I have added/updated tests
- [ ] I have added release note (CHANGELOG)
- [ ] I ran SwiftLint and fixed issues
- [ ] The PR is linked to a project card / issue

## Testing
Describe how this change was tested (simulator, device, iOS versions).

## Screenshots (if UI)
Attach before/after screenshots or GIFs.
EOF

# CI workflow
cat > .github/workflows/ci.yml <<'EOF'
name: iOS CI

on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ "**" ]

jobs:
  build-and-test:
    name: Build and Test
    runs-on: macos-latest
    timeout-minutes: 45
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.1'

      - name: Install xcodegen (optional)
        run: |
          if ! command -v xcodegen >/dev/null 2>&1; then
            brew install xcodegen || true
          fi

      - name: Generate Xcode project (xcodegen)
        run: |
          if [ -f project.yml ]; then
            xcodegen generate
          fi

      - name: Build app
        run: |
          set -o pipefail
          xcodebuild -project TestApp.xcodeproj -scheme TestApp -destination 'platform=iOS Simulator,name=iPhone 14,OS=17.0' clean build | xcpretty || true

      - name: Run tests
        run: |
          set -o pipefail
          xcodebuild test -project TestApp.xcodeproj -scheme TestApp -destination 'platform=iOS Simulator,name=iPhone 14,OS=17.0' | xcpretty -t || true

      - name: SwiftLint (optional)
        run: |
          if which swiftlint >/dev/null; then
            swiftlint
          else
            echo "swiftlint not installed, skipping"
          fi
EOF

# CD workflow
cat > .github/workflows/cd.yml <<'EOF'
name: iOS CD

on:
  push:
    branches:
      - main

permissions:
  contents: read
  id-token: write

jobs:
  build-and-deploy:
    name: Build and Deploy to TestFlight
    runs-on: macos-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.1'

      - name: Install dependencies
        run: |
          gem install bundler
          bundle install --jobs 4 --retry 3

      - name: Generate Xcode project (if using xcodegen)
        run: |
          if [ -f project.yml ]; then
            xcodegen generate
          fi

      - name: Run fastlane beta
        env:
          APP_STORE_CONNECT_API_KEY_JSON: ${{ secrets.APP_STORE_CONNECT_API_KEY_JSON }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
          FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD: ${{ secrets.FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD }}
        run: |
          bundle exec fastlane beta
EOF

# fastlane Fastfile
cat > fastlane/Fastfile <<'EOF'
default_platform(:ios)

platform :ios do
  desc "Run unit tests"
  lane :test do
    scan(
      project: "TestApp.xcodeproj",
      scheme: "TestApp",
      devices: ["iPhone 14"],
      clean: true,
      output_types: "junit"
    )
  end

  desc "Build and upload to TestFlight"
  lane :beta do
    # Use App Store Connect API key or match depending on your setup
    if ENV["APP_STORE_CONNECT_API_KEY_JSON"]
      app_store_connect_api_key(
        keyfile: "appstore_connect_key.json",
        in_house: false
      )
    end

    match(type: "appstore", readonly: false)
    build_app(project: "TestApp.xcodeproj", scheme: "TestApp", export_method: "app-store")
    upload_to_testflight(skip_waiting_for_build_processing: true)
  end
end
EOF

# fastlane Gemfile
cat > fastlane/Gemfile <<'EOF'
source "https://rubygems.org"

gem "fastlane", "~> 2.226"
gem "xcpretty", "~> 0.4.0"
EOF

# .github/SECRETS.md
cat > .github/SECRETS.md <<'EOF'
# Secrets required for CD (store these in Settings → Secrets → Actions)

- APP_STORE_CONNECT_API_KEY_JSON — App Store Connect API key JSON (if using token-based uploads).
- MATCH_GIT_URL — Git URL to your private fastlane match repo (e.g. https://github.com/<org>/<match-repo>.git)
- MATCH_PASSWORD — fastlane match password
- FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD — Application-specific password for App Store Connect uploads (optional)
- SENTRY_AUTH_TOKEN — optional, for dSYM uploads

How to add: Repository → Settings → Secrets and variables → Actions → New repository secret
EOF

# Project board script
cat > scripts/create_project_board.sh <<'EOF'
#!/usr/bin/env bash
# Usage: ./scripts/create_project_board.sh [owner/repo]
# Requires: gh CLI authenticated (https://cli.github.com/)
set -e

PROJECT_NAME="Test Workflow Board"
REPO="${1:-$GITHUB_REPOSITORY}"

if [ -z "$REPO" ]; then
  echo "Please pass owner/repo as first argument or set GITHUB_REPOSITORY env var"
  exit 1
fi

echo "Creating project board: $PROJECT_NAME in $REPO"
PROJECT_ID=$(gh project create --repo "$REPO" --name "$PROJECT_NAME" --body "PM → Dev → CI → QA → CD workflow board" --json id -q .id)
echo "Created project id: $PROJECT_ID"

for column in "Backlog" "Ready" "In Progress" "In Review" "QA" "Done"; do
  echo "Creating column: $column"
  gh api -X POST /projects/"$PROJECT_ID"/columns -f name="$column" >/dev/null
done

echo "Project board created. Add issues to columns using gh project column add-card <column-id> --content-id <issue-id>"
EOF
chmod +x scripts/create_project_board.sh

# PR description file
cat > "${PR_BODY_FILE}" <<'EOF'
## Summary
Add a minimal SwiftUI sample app plus full PM→Dev→CI→QA→CD setup.

## What this PR contains
- xcodegen project.yml (TestApp)
- Sources/TestApp (SwiftUI app + ContentView)
- Tests/TestAppTests (XCTest)
- .github/ISSUE_TEMPLATE (bug_report.md, feature_request.md)
- .github/PULL_REQUEST_TEMPLATE.md
- .github/workflows/ci.yml (build & test)
- .github/workflows/cd.yml (build & deploy to TestFlight via fastlane with match)
- fastlane/Fastfile + fastlane/Gemfile
- scripts/create_project_board.sh (gh CLI script for project board)
- .github/SECRETS.md
- README.md

## Required repo secrets (do NOT commit these)
- APP_STORE_CONNECT_API_KEY_JSON
- MATCH_GIT_URL
- MATCH_PASSWORD
- FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD
- SENTRY_AUTH_TOKEN (optional)

## How to test locally
1. Install xcodegen and run `xcodegen generate` (if using project.yml).
2. Open TestApp.xcodeproj in Xcode or run:
   xcodebuild -project TestApp.xcodeproj -scheme TestApp -destination 'platform=iOS Simulator,name=iPhone 14,OS=17.0' test
3. Run fastlane lanes locally:
   bundle exec fastlane test
   bundle exec fastlane beta

## Notes for admins / reviewers
- fastlane match is enabled; please create the private match repo and add MATCH_GIT_URL and MATCH_PASSWORD as secrets before CD will work.
- No sensitive credentials are committed by this script.
EOF

# Create COMMIT_LIST.md for reference
cat > COMMIT_LIST.md <<'EOF'
Files created by create_files.sh
- project.yml (xcodegen)
- Sources/TestApp/TestAppApp.swift
- Sources/TestApp/ContentView.swift
- Sources/TestApp/Info.plist
- Tests/TestAppTests/TestAppTests.swift
- .github/ISSUE_TEMPLATE/bug_report.md
- .github/ISSUE_TEMPLATE/feature_request.md
- .github/PULL_REQUEST_TEMPLATE.md
- .github/workflows/ci.yml
- .github/workflows/cd.yml
- fastlane/Fastfile
- fastlane/Gemfile
- .github/SECRETS.md
- scripts/create_project_board.sh
- README.md
- PR_DESCRIPTION.md
EOF

echo "All files written."

# Ask user whether to create/checkout branch, commit and push
read -r -p "Create/checkout branch '${BRANCH}', commit changes, and push to remote? [y/N] " DO_PUSH
DO_PUSH="${DO_PUSH:-N}"
if [[ "${DO_PUSH}" =~ ^[Yy]$ ]]; then
  echo "Creating/checking out branch ${BRANCH}..."
  # Create branch if it doesn't exist locally
  if git rev-parse --verify "${BRANCH}" >/dev/null 2>&1; then
    git checkout "${BRANCH}"
  else
    git checkout -b "${BRANCH}"
  fi

  echo "Staging files..."
  git add .

  echo "Committing..."
  git commit -m "Add iOS sample app, CI/CD, Fastlane (match enabled), and project board scripts/templates" || {
    echo "No changes to commit."
  }

  echo "Pushing to ${REMOTE}/${BRANCH}..."
  git push --set-upstream "${REMOTE}" "${BRANCH}"

  read -r -p "Would you like me to attempt to open a PR using gh CLI? (requires gh to be installed and authenticated) [y/N] " DO_PR
  DO_PR="${DO_PR:-N}"
  if [[ "${DO_PR}" =~ ^[Yy]$ ]]; then
    if command -v gh >/dev/null 2>&1; then
      echo "Opening PR..."
      gh pr create --base main --head "${BRANCH}" --title "${PR_TITLE}" --body-file "${PR_BODY_FILE}" || {
        echo "gh pr create failed. You can open the PR manually or check gh authentication."
      }
    else
      echo "gh CLI not found. Install it from https://cli.github.com/ and run the gh pr create command manually."
      echo "To open a PR manually, visit: https://github.com/$(git remote get-url "${REMOTE}" | sed -E 's/.*github.com[:\/](.+)\.git/\1/')/compare"
    fi
  else
    echo "Skipping PR creation. You can open a PR using gh or the web UI when ready."
  fi
else
  echo "Skipping commit/push. Run the following commands when you're ready to commit and push:"
  echo "  git checkout -b ${BRANCH}"
  echo "  git add ."
  echo "  git commit -m \"Add iOS sample app, CI/CD, Fastlane (match enabled), and project board scripts/templates\""
  echo "  git push --set-upstream ${REMOTE} ${BRANCH}"
  echo "Then open a PR (example using gh):"
  echo "  gh pr create --base main --head ${BRANCH} --title \"${PR_TITLE}\" --body-file ${PR_BODY_FILE}"
fi

echo ""
echo "Next steps (after pushing the branch and opening the PR):"
echo "1) Create a private fastlane match repo (example: <org>/ankithp1199-fastlane-match)."
echo "2) On a local machine with Apple credentials, run:"
echo "     bundle install --gemfile=fastlane/Gemfile"
echo "     bundle exec fastlane match init"
echo "     bundle exec fastlane match appstore"
echo "   This will populate the match repo with encrypted certificates/profiles."
echo "3) Add these GitHub repository secrets (Settings → Secrets and variables → Actions):"
echo "     - APP_STORE_CONNECT_API_KEY_JSON"
echo "     - MATCH_GIT_URL"
echo "     - MATCH_PASSWORD"
echo "     - FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD (optional)"
echo "     - SENTRY_AUTH_TOKEN (optional)"
echo "4) Run the project board script locally to create your board (requires gh CLI):"
echo "     ./scripts/create_project_board.sh <owner/repo>"
echo ""
echo "If you pushed and opened a PR, paste the PR URL here and I'll review the PR and help with CI/CD and match configuration."
