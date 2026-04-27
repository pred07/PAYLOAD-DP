#!/bin/bash

# Configuration
DATA_DIR="data"
TEMP_DIR=".tmp_payloads"
MASTER_LIST="${DATA_DIR}/payloads.txt"
META_FILE="${DATA_DIR}/meta.json"

# Target Repositories
REPOS=(
    "swisskyrepo/PayloadsAllTheThings"
    "danielmiessler/SecLists"
    "payloadbox/xss-payload-list"
    "payloadbox/sql-injection-payload-list"
)

mkdir -p "$DATA_DIR"
mkdir -p "$TEMP_DIR"

echo "[*] Initializing Deep Recursive Aggregation..."

# --- RECURSIVE DISCOVERY ---
discover_and_fetch() {
    local repo=$1
    echo "[*] Crawling: $repo"
    
    # Try master branch first
    tree_url="https://api.github.com/repos/${repo}/git/trees/master?recursive=1"
    response=$(curl -s "$tree_url")
    branch="master"
    
    # Fallback to main
    if [[ "$response" == *"Not Found"* ]]; then
        tree_url="https://api.github.com/repos/${repo}/git/trees/main?recursive=1"
        response=$(curl -s "$tree_url")
        branch="main"
    fi

    # Extract all .txt files while preserving spaces in paths
    # We use while loop with IFS= to handle spaces correctly
    echo "$response" | grep -oE '"path": "[^"]+\.txt"' | cut -d'"' -f4 | while IFS= read -r file; do
        # URL Encode the path (specifically spaces to %20)
        encoded_file=$(echo "$file" | sed 's/ /%20/g')
        raw_url="https://raw.githubusercontent.com/${repo}/${branch}/${encoded_file}"

        echo "  [+] Fetching: $file"
        out_name=$(echo "$raw_url" | md5sum | cut -d' ' -f1)
        
        if curl -sSL -f --connect-timeout 5 "$raw_url" -o "${TEMP_DIR}/${out_name}"; then
            # --- HARDENED NORMALIZATION ---
            cat "${TEMP_DIR}/${out_name}" | tr -d '\r' | tr '[:upper:]' '[:lower:]' | \
            sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
            sed '/^#/d; /^\/\//d' | \
            grep -avE "<html>|<!doctype|404 not found|permission denied|---" | \
            awk 'length($0) > 2' \
            > "${TEMP_DIR}/${out_name}.clean"
        fi
        rm -f "${TEMP_DIR}/${out_name}"
    done
}

# Execution
rm -f "$TEMP_DIR"/*
for repo in "${REPOS[@]}"; do
    discover_and_fetch "$repo"
done

# --- CATEGORIZATION ---
echo "[*] Compiling Master Database..."
cat "$TEMP_DIR"/*.clean 2>/dev/null | sort -u > "${TEMP_DIR}/new_master.txt"

if [ -s "${TEMP_DIR}/new_master.txt" ]; then
    # Precision Filtering
    grep -iE "(select|union|insert|update|delete|drop).*from|sleep\(|benchmark\(|information_schema" "${TEMP_DIR}/new_master.txt" | sort -u > "${DATA_DIR}/sqli.txt"
    grep -iE "<script|alert\(|onerror=|onload=|onclick=|prompt\(|confirm\(|<svg|<img" "${TEMP_DIR}/new_master.txt" | sort -u > "${DATA_DIR}/xss.txt"
    grep -iE "http://localhost|http://127\.0\.0\.1|http://169\.254|metadata\.google" "${TEMP_DIR}/new_master.txt" | sort -u > "${DATA_DIR}/ssrf.txt"
    grep -iE "\.\./\.\./|etc/passwd|windows/system32|boot\.ini" "${TEMP_DIR}/new_master.txt" | sort -u > "${DATA_DIR}/lfi.txt"
    grep -iE "\{\{.*\}\}|%7b%7b.*%7d%7d|\$\{.*\}|#\{.*\}" "${TEMP_DIR}/new_master.txt" | sort -u > "${DATA_DIR}/ssti.txt"
    grep -iE ";\s*id|;\s*whoami|;\s*cat|\|\s*id|\|\s*whoami|\$\(id\)|\`id\`" "${TEMP_DIR}/new_master.txt" | sort -u > "${DATA_DIR}/rce.txt"
    grep -iE "<!entity|<!doctype.*system" "${TEMP_DIR}/new_master.txt" | sort -u > "${DATA_DIR}/xxe.txt"
    grep -iE "//google\.com|//bing\.com|https?://[a-z0-9]+\.[a-z]+" "${TEMP_DIR}/new_master.txt" | grep -vE "localhost|127\.0\.0\.1" | sort -u > "${DATA_DIR}/redirect.txt"
    grep -iE "__proto__|constructor\.prototype" "${TEMP_DIR}/new_master.txt" | sort -u > "${DATA_DIR}/pollution.txt"

    mv "${TEMP_DIR}/new_master.txt" "$MASTER_LIST"
    
    # Metadata update
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    COUNT=$(wc -l < "$MASTER_LIST")
    cat <<EOF > "$META_FILE"
{
  "last_updated": "$TIMESTAMP",
  "total_payloads": $COUNT,
  "repo_coverage": ${#REPOS[@]},
  "status": "synchronized"
}
EOF
    echo "[*] Deep Sync Complete. Total Unique Payloads: $COUNT"
else
    echo "[!] Critical Error: Dataset is empty."
fi

rm -rf "$TEMP_DIR"
