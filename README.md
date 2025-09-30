# DrBenjamin.github.io

This repository hosts Dr. Benjamin's GitHub Pages site, featuring automated content synchronization from
- [Analytical-Skills-for-Business](https://github.com/DrBenjamin/Analytical-Skills-for-Business)
- [DrBenjamin/Data-Science-and-Data-Analytics](https://github.com/DrBenjamin/Data-Science-and-Data-Analytics) 
repositories. A static landing page links to the individual course HTML exports.

## Content Updates

The site synchronizes content from course materials using GitHub Actions workflows.

### How It Works

1. **Source Repositories**: Content is maintained in the two source repositories.
2. **Quarto (or other) Authoring**: Course material is authored in Quarto (`.qmd`) files and rendered to HTML.
3. **Automated Build**: This site’s workflow now checks out the source repositories, runs Quarto directly on the `.qmd` files to render fresh HTML and PDF artifacts, and stores them locally as:
   - `analytical-skills.html`
   - `data-science-analytics.html`
   - `Analytical_Skills_for_Business.pdf`
   - `Data_Science_and_Data_Analytics.pdf`
4. **Static Landing Page**: `index.html` is intentionally not overwritten; it links to the two course files.
5. **GitHub Pages Deployment**: Integrated into the unified workflow (build + deploy after successful renders).

### Automation Features

- **Scheduled Updates**: Runs daily at 3 AM Berlin time (CET/CEST)
- **Manual Triggering**: Can be triggered manually from the Actions tab

### Unified Workflow (`.github/workflows/update-content.yml`)

- Checks out both source repositories
- Sets up Python, R + Quarto (TinyTeX) environments
- Renders `Analytical_Skills_for_Business.qmd` and `Data_Science_and_Data_Analytics.qmd` (HTML + PDF)
- Copies/updates `analytical-skills.html`, `data-science-analytics.html`, PDFs, and resource directories
- Performs per-file change detection to avoid empty commits
- Builds Jekyll site (`_site/`) after content stage
- Deploys to GitHub Pages in the same workflow (separate deploy job)

## 🔧 Manual Operations

1. Go to the [Actions tab](https://github.com/DrBenjamin/DrBenjamin.github.io/actions)
2. Select "Update and deploy to GitHub Pages"
3. Click "Run workflow" > "Run workflow" (on main branch)
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
├── .Rprofile                            # R profiling configuration
├── environment.yml                      # Conda environment for R + Quarto
├── install-packages.R                   # R script to install required packages
├── index.html                           # Static landing page linking to course HTML
├── analytical-skills.html               # Synced and generated course material (Analytical Skills for Business)
├── data-science-analytics.html          # Synced and generated course material (Data Science and Data Analytics)
├── Analytical_Skills_for_Business.pdf   # Synced and generated PDF export for linking
├── Data_Science_and_Data_Analytics.pdf  # Synced and generated PDF export for linking
├── verify-automation.sh                 # Script to verify automation setup
└── README.md                            # This file
```

## 📊 Site Content

The landing page provides navigational access to two sets of course materials (Fresenius University of Applied Sciences – International Business School):

- Analytical Skills for Business (Master Studies in Business Administration) → `analytical-skills.html` / `Analytical_Skills_for_Business.pdf`
- Data Science and Data Analytics (Bachelor Studies in International Business Management) → `data-science-analytics.html` / `Data_Science_and_Data_Analytics.pdf`

### 💬 Comments Feature

The landing page includes a comments section powered by [giscus](https://giscus.app), which uses GitHub Discussions to enable:

- Students and visitors to leave comments and feedback
- Discussion threads on course materials
- Reactions and engagement with comments
- GitHub authentication for secure commenting

## 🔗 Related Repositories

- **Source Content**: [DrBenjamin/Analytical-Skills-for-Business](https://github.com/DrBenjamin/Analytical-Skills-for-Business)
- **Source Content**: [DrBenjamin/Data-Science-and-Data-Analytics](https://github.com/DrBenjamin/Data-Science-and-Data-Analytics)
- **Live Site**: [https://drbenjamin.github.io](https://drbenjamin.github.io)

### ✍️ Authoring Requirements

Ensure each source repository contains the expected Quarto file at its root:

```text
Analytical-Skills-for-Business: Analytical_Skills_for_Business.qmd
Data-Science-and-Data-Analytics: Data_Science_and_Data_Analytics.qmd
```
