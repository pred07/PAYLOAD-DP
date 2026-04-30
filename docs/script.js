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
    currentPayloads = [];

    try {
        // First try to load the main file
        const res = await fetch(`./data/${filename}`);
        if (res.ok) {
            const text = await res.text();
            currentPayloads = text.split('\n').map(l => l.trim()).filter(Boolean);
        } else {
            // If main file doesn't exist, try loading chunks (_part00, _part01...)
            let part = 0;
            let hasMore = true;
            const baseName = filename.replace('.txt', '');
            
            while (hasMore && part < 50) { // Safety limit of 50 chunks
                const partName = `${baseName}_part${part.toString().padStart(2, '0')}.txt`;
                const pRes = await fetch(`./data/${partName}`);
                if (pRes.ok) {
                    const pText = await pRes.text();
                    const pLines = pText.split('\n').map(l => l.trim()).filter(Boolean);
                    currentPayloads.push(...pLines);
                    part++;
                } else {
                    hasMore = false;
                }
            }
        }

        if (currentPayloads.length === 0) throw new Error('Empty');
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

let currentDisplayList = [];
const itemsPerPage = 500;
let displayedCount = 0;

function createPayloadRow(payload) {
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
    return row;
}

function renderPayloads(list) {
    const bar  = document.getElementById('payload-count-bar');
    const box  = document.getElementById('payload-list');
    box.innerHTML = '';
    currentDisplayList = list;
    displayedCount = 0;

    if (!list.length) {
        bar.textContent = '0 payloads';
        box.innerHTML = `<div class="payload-empty">// NO PAYLOADS IN THIS CATEGORY</div>`;
        return;
    }

    showNextBatch();
}

function showNextBatch() {
    const box = document.getElementById('payload-list');
    const bar = document.getElementById('payload-count-bar');
    
    // Remove existing "Load More" button container
    const existingMore = document.querySelector('.load-more-container');
    if (existingMore) existingMore.remove();

    const start = displayedCount;
    const end = Math.min(start + itemsPerPage, currentDisplayList.length);
    const batch = currentDisplayList.slice(start, end);
    
    const frag = document.createDocumentFragment();
    batch.forEach(payload => {
        frag.appendChild(createPayloadRow(payload));
    });
    
    box.appendChild(frag);
    displayedCount = end;
    
    bar.textContent = `Showing ${displayedCount.toLocaleString()} of ${currentDisplayList.length.toLocaleString()} payloads`;
    
    if (displayedCount < currentDisplayList.length) {
        const container = document.createElement('div');
        container.className = 'load-more-container';
        
        const btn = document.createElement('button');
        btn.className = 'load-more-btn';
        btn.textContent = `Load More (${(currentDisplayList.length - displayedCount).toLocaleString()} remaining)`;
        btn.addEventListener('click', () => showNextBatch());
        
        container.appendChild(btn);
        box.appendChild(container);
    }
}

// ── SEARCH ───────────────────────────────────────────────────────────────
document.getElementById('search-input').addEventListener('input', e => {
    const q = e.target.value.toLowerCase().trim();
    
    // Smart Jump: If search matches a category name, switch to it
    const tabs = document.querySelectorAll('.tab-btn');
    const matchedTab = Array.from(tabs).find(t => t.textContent.toLowerCase() === q);
    
    if (matchedTab && !matchedTab.classList.contains('active')) {
        tabs.forEach(b => b.classList.remove('active'));
        matchedTab.classList.add('active');
        loadPayloads(matchedTab.dataset.file);
        // Clear search after jump to show the full category
        setTimeout(() => { e.target.value = ''; }, 500);
        return;
    }

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
