# Trigger Content Update in GitHub Pages Repository

This workflow should be added to the Analytical-Skills-for-Business repository to automatically trigger content updates in the GitHub Pages site when the HTML file is updated.

## Setup Instructions

1. **Add this workflow to the source repository** (DrBenjamin/Analytical-Skills-for-Business):

   Create `.github/workflows/trigger-pages-update.yml` with the following content:

```yaml
name: Trigger GitHub Pages Update

on:
  push:
    branches: ["main"]
    paths: 
      - "Analytical_Skills_for_Business.html"
      - "Analytical_Skills_for_Business.qmd"
  
  workflow_dispatch:

jobs:
  trigger-update:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger GitHub Pages repository update
        run: |
          curl -X POST \
            -H "Accept: application/vnd.github.v3+json" \
            -H "Authorization: token ${{ secrets.PAGES_TRIGGER_TOKEN }}" \
            "https://api.github.com/repos/DrBenjamin/DrBenjamin.github.io/dispatches" \
            -d '{"event_type":"content-update","client_payload":{"repository":"Analytical-Skills-for-Business","updated_file":"Analytical_Skills_for_Business.html"}}'
          
          echo "✅ Triggered content update in GitHub Pages repository"
```

2. **Create a Personal Access Token**:
   - Go to GitHub Settings > Developer settings > Personal access tokens > Tokens (classic)
   - Generate a new token with `repo` scope
   - Add this token as a secret named `PAGES_TRIGGER_TOKEN` in the Analytical-Skills-for-Business repository

3. **Alternative: Manual Triggering**:
   If you prefer not to set up automatic triggering, you can manually run the "Update Content from Analytical Skills Repository" workflow in the GitHub Pages repository whenever you want to sync the content.

## How It Works

1. When you update the Quarto document (`.qmd`) or HTML file in the Analytical-Skills-for-Business repository, it triggers the workflow in that repository
2. The workflow sends a repository dispatch event to the GitHub Pages repository
3. The GitHub Pages repository receives this event and runs the content update workflow
4. The content update workflow downloads the latest HTML file and updates the GitHub Pages site
5. Jekyll automatically rebuilds and deploys the updated site

## Manual Sync

You can also manually trigger the content sync by:
1. Going to the GitHub Pages repository Actions tab
2. Selecting "Update Content from Analytical Skills Repository" workflow
3. Clicking "Run workflow"