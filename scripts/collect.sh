#!/bin/bash

# Configuration
SOURCES_FILE="sources.txt"
DATA_DIR="data"
TEMP_DIR=".tmp_payloads"
MASTER_LIST="${DATA_DIR}/payloads.txt"
METADATA_FILE="${DATA_DIR}/metadata.json"

# Create directories
mkdir -p "$DATA_DIR"
mkdir -p "$TEMP_DIR"

echo "[*] Starting payload collection..."

# Clear temporary files
rm -f "$TEMP_DIR"/*

# Fetch sources
while IFS= read -r url || [ -n "$url" ]; do
    # Skip comments and empty lines
    [[ "$url" =~ ^#.*$ ]] && continue
    [[ -z "$url" ]] && continue

    filename=$(echo "$url" | md5sum | cut -d' ' -f1)
    echo "[+] Fetching: $url"
    
    # Fetch with timeout and retry
    if curl -sSL --connect-timeout 10 --retry 3 "$url" -o "${TEMP_DIR}/${filename}"; then
        # Normalization: trim, remove comments, remove empty lines, lowercase
        sed -i 's/^[[:space:]]*//;s/[[:space:]]*$//' "${TEMP_DIR}/${filename}" # Trim
        sed -i '/^#/d; /^\/\//d' "${TEMP_DIR}/${filename}" # Remove # and // comments
        sed -i '/^$/d' "${TEMP_DIR}/${filename}" # Remove empty lines
        tr '[:upper:]' '[:lower:]' < "${TEMP_DIR}/${filename}" > "${TEMP_DIR}/${filename}.tmp" && mv "${TEMP_DIR}/${filename}.tmp" "${TEMP_DIR}/${filename}"
    else
        echo "[!] Failed to fetch: $url"
    fi
done < "$SOURCES_FILE"

# Combine and deduplicate
echo "[*] Processing master list..."
cat "$TEMP_DIR"/* | sort -u > "${TEMP_DIR}/master_raw.txt"

# Categorization logic
echo "[*] Categorizing payloads..."
grep -iE "select|union|insert|update|delete|drop|eval|benchmark|sleep" "${TEMP_DIR}/master_raw.txt" | sort -u > "${DATA_DIR}/sqli.txt"
grep -iE "script|alert|onerror|onload|svg|img|iframe|javascript" "${TEMP_DIR}/master_raw.txt" | sort -u > "${DATA_DIR}/xss.txt"
grep -iE "http|https|localhost|127.0.0.1|metadata|aws|gcp|azure" "${TEMP_DIR}/master_raw.txt" | sort -u > "${DATA_DIR}/ssrf.txt"
grep -iE "\{\{|%7b%7b|%24%7b|\$\{|\#\{" "${TEMP_DIR}/master_raw.txt" | sort -u > "${DATA_DIR}/ssti.txt"
grep -iE "etc/passwd|boot.ini|windows/system32|/etc/|/var/www/|C:/" "${TEMP_DIR}/master_raw.txt" | sort -u > "${DATA_DIR}/lfi.txt"

# Master list update
if [ -f "$MASTER_LIST" ]; then
    cp "$MASTER_LIST" "${TEMP_DIR}/old_master.txt"
fi

mv "${TEMP_DIR}/master_raw.txt" "$MASTER_LIST"

# Metadata generation
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOTAL_COUNT=$(wc -l < "$MASTER_LIST")
SQLI_COUNT=$(wc -l < "${DATA_DIR}/sqli.txt")
XSS_COUNT=$(wc -l < "${DATA_DIR}/xss.txt")
SSRF_COUNT=$(wc -l < "${DATA_DIR}/ssrf.txt")

cat <<EOF > "$METADATA_FILE"
{
  "last_updated": "$TIMESTAMP",
  "total_payloads": $TOTAL_COUNT,
  "categories": {
    "sqli": $SQLI_COUNT,
    "xss": $XSS_COUNT,
    "ssrf": $SSRF_COUNT
  }
}
EOF

# Comparison summary
if [ -f "${TEMP_DIR}/old_master.txt" ]; then
    NEW_COUNT=$(comm -13 <(sort "${TEMP_DIR}/old_master.txt") <(sort "$MASTER_LIST") | wc -l)
    REM_COUNT=$(comm -23 <(sort "${TEMP_DIR}/old_master.txt") <(sort "$MASTER_LIST") | wc -l)
    echo "[*] Summary: $NEW_COUNT new payloads added, $REM_COUNT payloads removed."
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo "[*] Done! Total payloads: $TOTAL_COUNT"
