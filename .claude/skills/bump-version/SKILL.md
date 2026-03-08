---
name: bump-version
description: Bump library version in VERSION file and prepare release notes
disable-model-invocation: true
argument-hint: "<major|minor|patch>"
---

# Bump Version

Bump the MESA library version and prepare for release.

**Input:** $ARGUMENTS

---

## Step 1: Parse Input

Determine what to bump:
- `major` → increment major, reset minor and patch to 0
- `minor` → increment minor, reset patch to 0
- `patch` → increment patch

If no level is provided, ask the user which bump type they want.

---

## Step 2: Read Current Version

Read the `VERSION` file at the repository root to get the current version string.

---

## Step 3: Calculate New Version

Apply semantic versioning and display the version change for confirmation:

```
Current → New
0.2.0   → 0.3.0
```

Ask the user to confirm before applying.

---

## Step 4: Apply Version Change

Update the `VERSION` file with the new version string.

---

## Step 5: Generate Release Notes

Gather commits since the last release tag:
- Run `git log $(git describe --tags --abbrev=0)..HEAD --oneline` to get commits since the last tag

Generate release notes grouped by category:
- **Features** — new functionality
- **Improvements** — enhancements to existing features
- **Bug Fixes** — corrections
- **Internal** — refactoring, CI, docs

Format as markdown suitable for a GitHub release.

---

## Step 6: Summary

Report:
- Previous and new version
- The expected release tag format: `v{VERSION}` (e.g., `v0.3.0`)
- The generated release notes
- Remind the user:
  1. Commit the VERSION change
  2. Push to main — a draft release will be created automatically by `draft-release.yml`
  3. Review and publish the draft release on GitHub
  4. `publish-release.yml` will validate the package on release publish
