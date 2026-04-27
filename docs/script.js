let currentPayloads = [];
let currentFile = 'sqli.txt';

// ── META ────────────────────────────────────────────────────────────────
async function loadMetadata() {
    try {
        const res = await fetch('./data/meta.json');
        if (!res.ok) throw new Error();
        const data = await res.json();
        document.getElementById('total-count').textContent =
            Number(data.total_payloads).toLocaleString();
        const d = new Date(data.last_updated);
        document.getElementById('last-updated').textContent =
            d.toLocaleString('en-US', { month:'short', day:'numeric', year:'numeric',
                hour:'2-digit', minute:'2-digit', timeZone:'UTC' }) + ' UTC';
    } catch {
        document.getElementById('total-count').textContent = '—';
        document.getElementById('last-updated').textContent = '—';
    }
}

// ── LOAD PAYLOADS ────────────────────────────────────────────────────────
async function loadPayloads(filename) {
    currentFile = filename;
    document.getElementById('payload-count-bar').textContent = 'Fetching...';
    document.getElementById('payload-list').innerHTML = '';

    try {
        const res = await fetch(`./data/${filename}`);
        if (!res.ok) throw new Error(res.status);
        const text = await res.text();
        currentPayloads = text.split('\n').map(l => l.trim()).filter(Boolean);
        renderPayloads(currentPayloads);
    } catch (e) {
        document.getElementById('payload-count-bar').textContent = '[!] FAILED TO LOAD FILE';
        document.getElementById('payload-list').innerHTML =
            `<div class="payload-empty">No data yet for this category — run ./scripts/collect.sh to populate.</div>`;
    }
}

// ── RENDER ───────────────────────────────────────────────────────────────
const COPY_ICON = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>`;
const CHECK_ICON = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>`;

function renderPayloads(list) {
    const bar  = document.getElementById('payload-count-bar');
    const box  = document.getElementById('payload-list');
    box.innerHTML = '';

    if (!list.length) {
        bar.textContent = '0 payloads';
        box.innerHTML = `<div class="payload-empty">// NO PAYLOADS IN THIS CATEGORY</div>`;
        return;
    }

    const display = list.slice(0, 500);
    bar.textContent = `Showing ${display.length.toLocaleString()} of ${list.length.toLocaleString()} payloads`;

    const frag = document.createDocumentFragment();
    display.forEach(payload => {
        const row = document.createElement('div');
        row.className = 'payload-item';

        const code = document.createElement('span');
        code.className = 'payload-text';
        code.textContent = payload;

        const btn = document.createElement('button');
        btn.className = 'copy-btn';
        btn.innerHTML = COPY_ICON;
        btn.title = 'Copy';
        btn.addEventListener('click', () => {
            navigator.clipboard.writeText(payload).then(() => {
                btn.innerHTML = CHECK_ICON;
                btn.classList.add('copied');
                setTimeout(() => {
                    btn.innerHTML = COPY_ICON;
                    btn.classList.remove('copied');
                }, 1800);
            });
        });

        row.appendChild(code);
        row.appendChild(btn);
        frag.appendChild(row);
    });

    if (list.length > 500) {
        const more = document.createElement('div');
        more.className = 'payload-empty';
        more.textContent = `// ${(list.length - 500).toLocaleString()} more — use search to filter`;
        frag.appendChild(more);
    }

    box.appendChild(frag);
}

// ── SEARCH ───────────────────────────────────────────────────────────────
document.getElementById('search-input').addEventListener('input', e => {
    const q = e.target.value.toLowerCase().trim();
    renderPayloads(q ? currentPayloads.filter(p => p.includes(q)) : currentPayloads);
});

// ── TABS ─────────────────────────────────────────────────────────────────
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById('search-input').value = '';
        loadPayloads(btn.dataset.file);
    });
});

// ── INIT ─────────────────────────────────────────────────────────────────
loadMetadata();
loadPayloads('sqli.txt');
