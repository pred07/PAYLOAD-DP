 # PAYLOAD-DP 🛡️

A production-ready, fully automated security payload aggregation system. It automatically collects, cleanses, deduplicates, and categorizes security payloads from multiple high-quality public repositories every 4 hours.

## 🚀 Features

- **Multi-Source Aggregation**: Pulls from over 15+ curated security repositories.
- **Automated Processing**: Cleans, normalizes (lowercase, trim), and deduplicates payloads.
- **Smart Categorization**: Automatically sorts payloads into SQLi, XSS, SSRF, SSTI, and LFI categories.
- **Zero Maintenance**: Powered by GitHub Actions; runs on a schedule with no manual intervention required.
- **Metadata Tracking**: Includes real-time statistics on total payload counts and category distributions.

## 📁 Project Structure

- `data/`: Contains the processed payload files.
  - `payloads.txt`: Master list of all unique payloads.
  - `sqli.txt`, `xss.txt`, `ssrf.txt`, etc.: Categorized lists.
  - `metadata.json`: Summary of the last update.
- `scripts/collect.sh`: The core engine for fetching and processing.
- `sources.txt`: Curated list of payload sources.
- `.github/workflows/update.yml`: GitHub Actions schedule configuration.

## ⚙️ Setup Instructions

1. **Fork/Clone** the repository.
2. **Push to GitHub**:
   ```bash
   git add .
   git commit -m "Initialize project"
   git push origin main
   ```
3. **Enable Actions**: GitHub Actions will automatically start running every 4 hours. You can also trigger it manually from the "Actions" tab.

## 🌐 Categories Included

- SQL Injection (SQLi)
- Cross-Site Scripting (XSS)
- Server-Side Request Forgery (SSRF)
- Server-Side Template Injection (SSTI)
- Local/Remote File Inclusion (LFI/RFI)

---
*Maintained automatically by PAYLOAD-DP Bot.*
