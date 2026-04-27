# EXPLOITDECK | Security Payload Database

## Overview
EXPLOITDECK is a high-performance, automated repository of security exploitation vectors. It serves as a centralized hub for penetration testing payloads across 20 distinct vulnerability categories. The database is updated automatically via a recursive crawling engine that aggregates data from over 90 specialized security repositories.

## Version
Current Version: 1.0.0

## Category Coverage
The database provides extensive coverage for the following vulnerability classes:
- SQL Injection (SQLi)
- Cross-Site Scripting (XSS)
- Server-Side Request Forgery (SSRF)
- Local File Inclusion (LFI)
- Server-Side Template Injection (SSTI)
- Command Injection (RCE)
- XML External Entity (XXE)
- Open Redirect
- NoSQL Injection
- LDAP Injection
- HTTP Headers Fuzzing
- JSON Web Token (JWT)
- CRLF Injection
- GraphQL Injection
- CORS Misconfiguration
- Insecure Deserialization
- Prototype Pollution
- Cloud Metadata Exploitation
- WordPress Discovery
- Advanced Encoding/Polyglots

## Database Structure
Data is organized into category-specific flat files for maximum compatibility with security tools:
- `/data/*.txt`: Individual category payload lists.
- `/data/payloads.txt`: Unified master payload list.
- `/data/meta.json`: Database metadata and update timestamps.

## Automation Pipeline
The repository utilizes GitHub Actions to maintain data freshness:
- **Crawling Engine**: Recursive discovery of new payloads from global security research.
- **Deduplication**: Automatic removal of redundant vectors to maintain list efficiency.
- **Validation**: Basic syntax verification and normalization of exploitation strings.

## Usage
Payloads can be utilized directly in security tools such as Burp Suite, ffuf, or custom automation scripts by referencing the raw URLs in the `/data` directory.

## License
This project is for educational and authorized penetration testing purposes only. Refer to the LICENSE file for details.
