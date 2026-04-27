let currentPayloads = [];

async function loadMetadata() {
    try {
        const response = await fetch('../data/meta.json');
        const data = await response.json();
        document.getElementById('total-count').textContent = data.total_payloads.toLocaleString();
        
        // Format date to: Month Day, Year HH:MM UTC
        const date = new Date(data.last_updated);
        const options = { month: 'long', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit', timeZone: 'UTC' };
        document.getElementById('last-updated').textContent = date.toLocaleString('en-US', options) + ' UTC';
    } catch (e) {
        console.error('Meta loading failed', e);
    }
}

async function loadPayloads(filename) {
    const listElement = document.getElementById('payload-list');
    listElement.innerHTML = '<div class="payload-item"><span class="payload-text">Initiating fetch protocol...</span></div>';
    
    try {
        const response = await fetch(`../data/${filename}`);
        if (!response.ok) throw new Error('Network response was not ok');
        const text = await response.text();
        currentPayloads = text.split('\n').filter(line => line.trim() !== '');
        renderPayloads(currentPayloads);
    } catch (e) {
        listElement.innerHTML = '<div class="payload-item"><span class="payload-text red">[!] ERROR: SECURE LINK FAILED</span></div>';
    }
}

function renderPayloads(list) {
    const listElement = document.getElementById('payload-list');
    listElement.innerHTML = '';
    
    if (list.length === 0) {
        listElement.innerHTML = '<div class="payload-item"><span class="payload-text text-dim">NO DATA DETECTED IN THIS SECTOR</span></div>';
        return;
    }

    // Performance optimization: render first 300
    const slice = list.slice(0, 300);
    
    slice.forEach(payload => {
        const div = document.createElement('div');
        div.className = 'payload-item';
        div.innerHTML = `
            <span class="payload-text">${escapeHtml(payload)}</span>
            <button class="copy-btn" onclick="copyToClipboard('${payload.replace(/'/g, "\\'")}', this)" title="Copy to clipboard">
                <i class="far fa-copy"></i>
            </button>
        `;
        listElement.appendChild(div);
    });

    if (list.length > 300) {
        const more = document.createElement('div');
        more.className = 'payload-item';
        more.style.justifyContent = 'center';
        more.innerHTML = `<span class="sub-title">BUFFER SATURATED: SHOWING 300 OF ${list.length} PAYLOADS. USE SEARCH TO FILTER.</span>`;
        listElement.appendChild(more);
    }
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function copyToClipboard(text, btn) {
    navigator.clipboard.writeText(text).then(() => {
        const icon = btn.querySelector('i');
        icon.className = 'fas fa-check';
        btn.style.color = '#00ff00';
        setTimeout(() => {
            icon.className = 'far fa-copy';
            btn.style.color = '';
        }, 2000);
    });
}

// Search functionality
document.getElementById('search-input').addEventListener('input', (e) => {
    const query = e.target.value.toLowerCase();
    const filtered = currentPayloads.filter(p => p.toLowerCase().includes(query));
    renderPayloads(filtered);
});

// Tab switching
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        loadPayloads(btn.dataset.file);
    });
});

// Init
loadMetadata();
loadPayloads('sqli.txt');
