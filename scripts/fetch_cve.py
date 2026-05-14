import requests
import json
import os
import sys
from datetime import datetime

# Configuration
DELTA_LOG_URL = "https://raw.githubusercontent.com/CVEProject/cvelistV5/main/cves/deltaLog.json"
OUTPUT_FILE = "docs/data/cve.txt"
MAX_CVES = 100  # Limit to avoid excessive requests

def fetch_cve_details(github_link):
    try:
        resp = requests.get(github_link, timeout=10)
        if resp.status_code == 200:
            data = resp.json()
            # Extract description from CVE JSON 5.0 format
            containers = data.get("containers", {})
            cna = containers.get("cna", {})
            descriptions = cna.get("descriptions", [])
            desc_text = "No description available."
            if descriptions:
                desc_text = descriptions[0].get("value", desc_text)
            
            # Extract title or affected product
            title = cna.get("title", "")
            if not title:
                affected = cna.get("affected", [])
                if affected:
                    title = affected[0].get("product", "")
            
            return {
                "title": title,
                "description": desc_text
            }
    except Exception as e:
        print(f"Error fetching {github_link}: {e}")
    return None

def main():
    print("[*] Fetching deltaLog.json...")
    try:
        resp = requests.get(DELTA_LOG_URL, timeout=20)
        if resp.status_code != 200:
            print(f"[!] Failed to fetch delta log: {resp.status_code}")
            return
        
        delta_log = resp.json()
        if not delta_log or not isinstance(delta_log, list):
            print("[!] Invalid delta log format.")
            return

        # Get the most recent entries
        recent_cves = []
        for entry in delta_log:
            new_cves = entry.get("new", [])
            updated_cves = entry.get("updated", [])
            
            # Combine and sort by date updated (descending)
            combined = new_cves + updated_cves
            combined.sort(key=lambda x: x.get("dateUpdated", ""), reverse=True)
            
            for cve in combined:
                if cve["cveId"] not in [x["cveId"] for x in recent_cves]:
                    recent_cves.append(cve)
                if len(recent_cves) >= MAX_CVES:
                    break
            if len(recent_cves) >= MAX_CVES:
                break

        print(f"[*] Found {len(recent_cves)} recent CVEs. Fetching details...")

        output_lines = []
        for i, cve in enumerate(recent_cves):
            cve_id = cve["cveId"]
            github_link = cve["githubLink"]
            print(f"    [{i+1}/{len(recent_cves)}] {cve_id}...", end="\r")
            
            details = fetch_cve_details(github_link)
            if details:
                title = details["title"]
                desc = details["description"].replace("\n", " ").strip()
                # Limit description length
                if len(desc) > 300:
                    desc = desc[:297] + "..."
                
                line = f"{cve_id} | {title if title else 'N/A'} | {desc}"
                output_lines.append(line)
        
        print("\n[*] Saving results to " + OUTPUT_FILE)
        os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            for line in output_lines:
                f.write(line + "\n")
        
        print("[*] CVE Intel update complete.")

    except Exception as e:
        print(f"[!] Main loop error: {e}")

if __name__ == "__main__":
    main()
