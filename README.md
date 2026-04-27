# 💀 EXPLOITDECK

> **Curated Offensive Payload Database**
> "Maximum coverage. Minimum noise. Professional-grade aggregation."

![Dashboard Mockup](https://raw.githubusercontent.com/pred07/PAYLOAD-DP/main/docs/screenshot.png)

## 🚀 Overview
**EXPLOITDECK** is a high-performance aggregation engine that crawls 90+ top-tier security repositories (PayloadsAllTheThings, SecLists, PayloadBox, etc.) to build a unified, deduplicated, and categorized database of web application vulnerabilities.

## ⚡ Key Features
- **90+ Repositories**: Deep recursive discovery across the entire security ecosystem.
- **20+ Categories**: Precision filtering for SQLi, XSS, SSRF, LFI, SSTI, RCE, JWT, and more.
- **Smart Cleanup**: Automatic removal of HTML boilerplate, 404 pages, and duplicate entries.
- **Premium UI**: Dark-mode dashboard with real-time search and copy-to-clipboard.
- **Auto-Sync**: GitHub Actions pipeline refreshes the database every 12 hours.

## 📂 Category Coverage
1.  **SQL Injection** (Error-based, Blind, Time-based)
2.  **Cross-Site Scripting (XSS)** (Tags, Handlers, Protocols)
3.  **SSRF** (Cloud Metadata, Internal IPs)
4.  **LFI / Path Traversal**
5.  **SSTI** (Template Injection)
6.  **RCE / Command Injection**
7.  **XXE** (XML External Entity)
8.  **Open Redirect**
9.  **NoSQL Injection**
10. **LDAP Injection**
11. **HTTP Header / Host Injection**
12. **JWT Attacks**
13. **CRLF / Header Injection**
14. **GraphQL / Introspection**
15. **CORS Bypass**
16. **Insecure Deserialization**
17. **Prototype Pollution**
18. **Cloud Metadata (AWS/GCP/Azure)**
19. **WordPress Specific**
20. **Encoding / Bypass / Obfuscation**

## 🛠️ Usage
### Local Run
```bash
# Aggregates payloads from all sources
./scripts/collect.sh
```

### Dashboard
Open `docs/index.html` in your browser to access the interactive dashboard.

## 🤝 Contributing
Found a missing repo or category? Open an issue or a casual PR.

---
*Built for security researchers and penetration testers.*
