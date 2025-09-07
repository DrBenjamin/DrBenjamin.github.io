# DrBenjamin.github.io

This repository hosts Dr. Benjamin's GitHub Pages site, featuring automated content synchronization from the [Analytical-Skills-for-Business](https://github.com/DrBenjamin/Analytical-Skills-for-Business) and [DrBenjamin/Data-Science-and-Data-Analytics](https://github.com/DrBenjamin/Data-Science-and-Data-Analytics) repositories. A lightweight static landing page (`index.html`) links to the individual course HTML exports.

## 🤖 Automated Content Updates

The site automatically synchronizes content from the course materials using GitHub Actions workflows.

### How It Works

1. **Source Repositories**: Content is maintained in the two source repositories above.
2. **Quarto (or other) Authoring**: Course material is authored (e.g. in Quarto `.qmd`) and rendered to HTML inside each source repository.
3. **Automated Build**: This site’s workflow now checks out the source repositories, runs Quarto directly on the `.qmd` files to render fresh HTML and PDF artifacts (on schedule or manual trigger), and stores them locally as:
   - `analytical-skills.html`
   - `data-science-analytics.html`
   - `Analytical_Skills_for_Business.pdf`
   - `Data_Science_and_Data_Analytics.pdf`
4. **Static Landing Page**: `index.html` is intentionally not overwritten; it links to the two course files.
5. **GitHub Pages Deployment**: Integrated into the unified workflow (build + deploy after successful renders).

### Automation Features

- **Scheduled Updates**: Runs daily at 3 AM Berlin time (CET/CEST)
- **Manual Triggering**: Can be triggered manually from the Actions tab
- **Change Detection**: Only updates when content has actually changed
- **Automatic Deployment**: Leverages Jekyll's GitHub Pages integration for seamless deployment

### Unified Workflow (`.github/workflows/update-content.yml`)

- Checks out both source repositories
- Sets up R + Quarto (TinyTeX) environment
- Renders `Analytical_Skills_for_Business.qmd` and `Data_Science_and_Data_Analytics.qmd` (HTML + PDF)
- Copies/updates `analytical-skills.html`, `data-science-analytics.html`, PDFs, and resource directories
- Performs per-file change detection to avoid empty commits
- Builds Jekyll site (`_site/`) after content stage
- Deploys to GitHub Pages in the same workflow (separate deploy job)

## 🔧 Manual Operations

### Triggering Content Update

1. Go to the [Actions tab](https://github.com/DrBenjamin/DrBenjamin.github.io/actions)
2. Select "Update course contents and Deploy to GitHub Pages"
3. Click "Run workflow" > "Run workflow" (no inputs required)
4. Wait for both jobs: `update-content` then `deploy` to succeed

### Testing the Setup

Run the verification script to test the automation:

```bash
./verify-automation.sh
```

## 📁 Repository Structure

```text
.
├── .github/
│   └── copilot-instructions.md          # Instructions for GitHub Copilot
│   └── workflows/
│       └── update-content.yml           # Unified content build + Pages deploy
├── .gitignore                           # Ignore files for Git
├── .Rprofile                           # R profiling configuration
├── environment.yml                      # Conda environment for R + Quarto
├── index.html                           # Static landing page linking to course HTML
├── analytical-skills.html (generated)   # Synced course material (master level)
├── data-science-analytics.html (generated) # Synced course material (bachelor level)
├── Analytical_Skills_for_Business.pdf (generated) # PDF export for linking
├── Data_Science_and_Data_Analytics.pdf (generated) # PDF export for linking
├── verify-automation.sh                 # Script to verify automation setup
└── README.md                            # This file
```

## 📊 Site Content

The site provides navigational access to two sets of course materials (Fresenius University of Applied Sciences – International Business School):

- Analytical Skills for Business (Master Studies in Business Administration) → `analytical-skills.html` / `Analytical_Skills_for_Business.pdf`
- Data Science and Data Analytics (Bachelor Studies in International Business Management) → `data-science-analytics.html` / `Data_Science_and_Data_Analytics.pdf`

## 🔗 Related Repositories

- **Source Content**: [DrBenjamin/Analytical-Skills-for-Business](https://github.com/DrBenjamin/Analytical-Skills-for-Business)
- **Source Content**: [DrBenjamin/Data-Science-and-Data-Analytics](https://github.com/DrBenjamin/Data-Science-and-Data-Analytics)
- **Live Site**: [https://drbenjamin.github.io](https://drbenjamin.github.io)

## Fixing Update / Deployment Issues

If changes are not visible:

1. Run unified workflow manually (if not already running).
2. Hard refresh your browser (Cmd+Shift+R / Ctrl+F5) or append a cache buster `?v=TIMESTAMP`.
3. Confirm logs in `update-content` show renders; `deploy` finished successfully.
4. Verify source `.qmd` changes exist in their repos.

If a source `.qmd` file is missing, the workflow logs a warning and skips that course. No commit occurs unless at least one rendered output (HTML / PDF / resources) changed.

## ✍️ Authoring Requirements

Ensure each source repository contains the expected Quarto file at its root:

```text
Analytical-Skills-for-Business/Analytical_Skills_for_Business.qmd
Data-Science-and-Data-Analytics/Data_Science_and_Data_Analytics.qmd
```

Optional supporting assets (images, data) should be referenced with relative paths inside the repositories. Quarto-generated resource directories like `Analytical_Skills_for_Business_files/` are copied to the site root when they change.

## 🔄 Regenerating Immediately

After pushing changes to either `.qmd` source file, manually trigger the workflow to publish the updated HTML/PDF without waiting for the daily schedule.
