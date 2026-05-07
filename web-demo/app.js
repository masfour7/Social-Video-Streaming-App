'use strict';

// ── Screen switching ──────────────────────────────────────────────────────────
function switchScreen(name) {
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
  document.getElementById('screen-' + name).classList.add('active');
  document.getElementById('nav-' + name).classList.add('active');
}

// ── Like button ───────────────────────────────────────────────────────────────
function like(btn) {
  const icon  = btn.querySelector('.action-icon');
  const count = btn.querySelector('.action-count');
  const liked = btn.dataset.liked === 'true';

  if (liked) {
    btn.dataset.liked = 'false';
    icon.style.filter = '';
    icon.style.transform = '';
  } else {
    btn.dataset.liked = 'true';
    icon.style.filter  = 'drop-shadow(0 0 6px rgba(254,44,85,1))';
    icon.style.transform = 'scale(1.4)';
    icon.style.transition = 'transform .2s';
    setTimeout(() => { icon.style.transform = 'scale(1)'; }, 200);
    // Bump count
    const raw = count.textContent.replace(/[KM]/g, '');
    const suffix = count.textContent.match(/[KM]/)?.[0] || '';
    count.textContent = (parseFloat(raw) + (suffix === 'K' ? 0.1 : suffix === 'M' ? 0.1 : 1)).toFixed(1).replace(/\.0$/, '') + suffix;
  }
}

// ── Camera: focus tap ─────────────────────────────────────────────────────────
document.querySelector('.camera-preview')?.addEventListener('click', (e) => {
  const ring = document.getElementById('focusRing');
  const rect = e.currentTarget.getBoundingClientRect();
  const x = e.clientX - rect.left;
  const y = e.clientY - rect.top;
  ring.style.left = x + 'px';
  ring.style.top  = y + 'px';
  ring.classList.remove('active');
  void ring.offsetWidth;
  ring.classList.add('active');
  setTimeout(() => ring.classList.remove('active'), 800);
});

// ── Camera: flip ─────────────────────────────────────────────────────────────
let flipped = false;
function flipCam() {
  const preview = document.querySelector('.camera-preview');
  preview.style.transition = 'transform .3s';
  preview.style.transform  = flipped ? 'scaleX(1)' : 'scaleX(-1)';
  flipped = !flipped;
  showToast(flipped ? '📸 Switched to front camera' : '📸 Switched to rear camera');
}

// ── Camera: record ────────────────────────────────────────────────────────────
let recordInterval = null;
let recSeconds = 0;
let isRecording = false;

function startRecord() {
  if (isRecording) return;
  isRecording = true;
  recSeconds = 0;

  const inner    = document.getElementById('recordInner');
  const recInfo  = document.getElementById('recInfo');
  const recTime  = document.getElementById('recTime');
  const progress = document.getElementById('recProgress');
  const circ     = 2 * Math.PI * 44; // circumference

  inner.classList.add('recording');
  recInfo.style.display = 'flex';

  recordInterval = setInterval(() => {
    recSeconds++;
    recTime.textContent = recSeconds + ' sec';
    const pct = Math.min(recSeconds / 60, 1);
    progress.style.strokeDashoffset = circ * (1 - pct);
    if (recSeconds >= 60) stopRecord();
  }, 1000);
}

function stopRecord() {
  if (!isRecording) return;
  isRecording = false;
  clearInterval(recordInterval);

  const inner    = document.getElementById('recordInner');
  const recInfo  = document.getElementById('recInfo');
  const progress = document.getElementById('recProgress');
  const circ     = 2 * Math.PI * 44;

  inner.classList.remove('recording');
  recInfo.style.display = 'none';
  progress.style.strokeDashoffset = circ;
  recSeconds = 0;

  if (recSeconds > 0 || true) {
    showToast('✅ Video saved — tap Next to upload');
  }
}

function snapPhoto() {
  if (isRecording) return;
  // Brief white flash
  const preview = document.querySelector('.camera-preview');
  preview.style.transition = 'opacity .1s';
  preview.style.opacity = '0.05';
  setTimeout(() => { preview.style.opacity = '1'; }, 120);
  showToast('📷 Photo captured');
}

// ── Upload toast ──────────────────────────────────────────────────────────────
function showUploadToast() {
  showToast('📁 Gallery picker — pick a video to upload');
}

// ── Toast helper ──────────────────────────────────────────────────────────────
let toastTimer = null;
function showToast(msg) {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove('show'), 2800);
}

// ── Keyboard shortcuts ────────────────────────────────────────────────────────
document.addEventListener('keydown', (e) => {
  if (e.key === 'ArrowUp' || e.key === 'ArrowDown') {
    const feed = document.getElementById('feedContainer');
    if (!feed) return;
    feed.scrollBy({ top: e.key === 'ArrowDown' ? feed.clientHeight : -feed.clientHeight, behavior: 'smooth' });
    e.preventDefault();
  }
});

// ── Hide swipe hint on first scroll ──────────────────────────────────────────
document.getElementById('feedContainer')?.addEventListener('scroll', () => {
  const hint = document.getElementById('swipeHint');
  if (hint) hint.style.opacity = '0';
}, { once: true });
