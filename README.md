# DrBenjamin.github.io

This repository hosts Dr. Benjamin's GitHub Pages site, featuring automated content synchronization from the [Analytical-Skills-for-Business](https://github.com/DrBenjamin/Analytical-Skills-for-Business) repository.

## 🤖 Automated Content Updates

The site automatically synchronizes content from the Analytical Skills for Business course materials using GitHub Actions workflows.

> **❓ Need to know about manual setup?** See [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) for a complete breakdown of what works automatically vs. what requires manual configuration.

### How It Works

1. **Source Repository**: Content is maintained in [DrBenjamin/Analytical-Skills-for-Business](https://github.com/DrBenjamin/Analytical-Skills-for-Business)
2. **Quarto Document**: The main content is written as a Quarto document (`.qmd` file)
3. **HTML Generation**: Quarto renders the document to HTML
4. **Automated Sync**: GitHub Actions automatically fetches the latest HTML and updates this site
5. **Jekyll Deployment**: GitHub Pages automatically deploys the updated content using Jekyll

### Automation Features

- **Scheduled Updates**: Runs daily at 6 AM UTC
- **Manual Triggering**: Can be triggered manually from the Actions tab
- **Change Detection**: Only updates when content has actually changed
- **Automatic Deployment**: Leverages Jekyll's GitHub Pages integration for seamless deployment

### Workflows

#### 1. Content Update Workflow (`.github/workflows/update-content.yml`)
- Downloads the latest HTML content from the source repository
- Compares with existing content to detect changes
- Updates the site and commits changes if content has changed
- Provides detailed logging and status reporting

#### 2. Jekyll Deployment (`.github/workflows/jekyll-gh-pages.yml`)
- Standard GitHub Pages Jekyll workflow
- Automatically triggered when content is updated
- Builds and deploys the site to GitHub Pages

## 🔧 Manual Operations

### Triggering Content Update
1. Go to the [Actions tab](https://github.com/DrBenjamin/DrBenjamin.github.io/actions)
2. Select "Update Content from Analytical Skills Repository"
3. Click "Run workflow" > "Run workflow"

### Testing the Setup
Run the verification script to test the automation:
```bash
./verify-automation.sh
```

## 📁 Repository Structure

```
.
├── .github/
│   └── workflows/
│       ├── jekyll-gh-pages.yml      # Jekyll deployment workflow
│       └── update-content.yml       # Content synchronization workflow
├── index.html                       # Main site content (auto-updated)
├── verify-automation.sh             # Script to verify automation setup
└── README.md                        # This file
```

## 📊 Site Content

The site displays the course material for courses at the Fresenius University of Applied Sciences - International Business School.

- Analytical Skills for Business (Master Studies in Business Administration)
- Data Science and Data Analytics (Bachelor Studies in International Business Management)

## 🔗 Related Repositories

- **Source Content**: [DrBenjamin/Analytical-Skills-for-Business](https://github.com/DrBenjamin/Analytical-Skills-for-Business)
- **Live Site**: [https://drbenjamin.github.io](https://drbenjamin.github.io)

## Fixing update issues on GitHub Pages

If you encounter issues with GitHub Pages not reflecting the latest updates, try the following steps:

1. Go to the [Actions tab](https://github.com/DrBenjamin/DrBenjamin.github.io/actions)
2. Select "Deploy Jekyll with GitHub Pages dependencies preinstalled"
3. Click "Run workflow" > "Run workflow"
4. This forces a rebuild and redeployment
