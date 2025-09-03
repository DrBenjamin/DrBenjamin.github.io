# DrBenjamin.github.io

This repository hosts Dr. Benjamin's GitHub Pages site, featuring automated content synchronization from the [Analytical-Skills-for-Business](https://github.com/DrBenjamin/Analytical-Skills-for-Business) and [DrBenjamin/Data-Science-and-Data-Analytics](https://github.com/DrBenjamin/Data-Science-and-Data-Analytics) repositories. A lightweight static landing page (`index.html`) links to the individual course HTML exports.

## 🤖 Automated Content Updates

The site automatically synchronizes content from the course materials using GitHub Actions workflows.

### How It Works

1. **Source Repositories**: Content is maintained in the two source repositories above.
2. **Quarto (or other) Authoring**: Course material is authored (e.g. in Quarto `.qmd`) and rendered to HTML inside each source repository.
3. **Automated Sync**: This site’s workflow downloads the published HTML files daily (or on manual trigger) and stores them locally as:
   - `analytical-skills.html`
   - `data-science-analytics.html`
4. **Static Landing Page**: `index.html` is intentionally not overwritten; it links to the two course files.
5. **GitHub Pages Deployment**: The Jekyll Pages workflow deploys any changed HTML assets.

### Automation Features

- **Scheduled Updates**: Runs daily at 6 AM UTC
- **Manual Triggering**: Can be triggered manually from the Actions tab
- **Change Detection**: Only updates when content has actually changed
- **Automatic Deployment**: Leverages Jekyll's GitHub Pages integration for seamless deployment

### Workflows

#### 1. Course Content Sync (`.github/workflows/update-content.yml`)

- Downloads the latest HTML from both source repositories
- Saves/updates `analytical-skills.html` and `data-science-analytics.html`
- Performs change detection (per file) to avoid empty commits
- Leaves `index.html` untouched (acts as stable landing page)
- Commits only when at least one course file changed

#### 2. Jekyll Deployment (`.github/workflows/jekyll-gh-pages.yml`)

- Standard GitHub Pages Jekyll workflow
- Automatically triggered when content is updated
- Builds and deploys the site to GitHub Pages

## 🔧 Manual Operations

### Triggering Content Update

1. Go to the [Actions tab](https://github.com/DrBenjamin/DrBenjamin.github.io/actions)
2. Select "Update Course Content (Analytical + Data Science)"
3. Click "Run workflow" > "Run workflow" (no inputs required)

### Testing the Setup

Run the verification script to test the automation:

```bash
./verify-automation.sh
```

## 📁 Repository Structure

```text
.
├── .github/
│   └── workflows/
│       ├── jekyll-gh-pages.yml          # Jekyll deployment workflow
│       └── update-content.yml           # Multi-repo content sync workflow
├── index.html                           # Static landing page linking to course HTML
├── analytical-skills.html (generated)   # Synced course material (master level)
├── data-science-analytics.html (generated) # Synced course material (bachelor level)
├── verify-automation.sh             # Script to verify automation setup
└── README.md                        # This file
```

## 📊 Site Content

The site provides navigational access to two sets of course materials (Fresenius University of Applied Sciences – International Business School):

- Analytical Skills for Business (Master Studies in Business Administration) → `analytical-skills.html`
- Data Science and Data Analytics (Bachelor Studies in International Business Management) → `data-science-analytics.html`

## 🔗 Related Repositories

- **Source Content**: [DrBenjamin/Analytical-Skills-for-Business](https://github.com/DrBenjamin/Analytical-Skills-for-Business)
- **Source Content**: [DrBenjamin/Data-Science-and-Data-Analytics](https://github.com/DrBenjamin/Data-Science-and-Data-Analytics)
- **Live Site**: [https://drbenjamin.github.io](https://drbenjamin.github.io)

## Fixing Update / Deployment Issues

If changes are not visible:

1. Manually run the Jekyll deployment workflow: "Deploy Jekyll with GitHub Pages dependencies preinstalled".
2. Hard refresh your browser (Cmd+Shift+R / Ctrl+F5) or append a cache buster `?v=TIMESTAMP`.
3. Confirm the content sync workflow shows the updated file names in its log.
4. Check that the source repositories actually committed the regenerated HTML.

If a source HTML file is temporarily missing, the workflow logs a warning but continues (other file still updates). No commit occurs unless at least one file changes.
