let quotes = [];
let pool = [];
let current = null;
let score = 0;
let streak = 0;
let speedMode = false;
let timer = null;
let timeLeft = 10;
const TIME_LIMIT = 10;
const HIGH_KEY = 'quotable_high_score';
const SFX_ON_KEY = 'quotable_sfx_on';
const SFX_VOL_KEY = 'quotable_sfx_vol';

const $ = (id) => document.getElementById(id);

let audioCtx = null;
function beep(freq, duration) {
  if ($('sfx-toggle') && !$('sfx-toggle').checked) return;
  const vol = ($('sfx-volume') ? $('sfx-volume').value : 60) / 100;
  if (vol <= 0) return;
  audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();
  const osc = audioCtx.createOscillator();
  const gain = audioCtx.createGain();
  osc.frequency.value = freq;
  gain.gain.value = vol * 0.2;
  osc.connect(gain).connect(audioCtx.destination);
  osc.start();
  osc.stop(audioCtx.currentTime + duration);
}

function initSettings() {
  const toggle = $('sfx-toggle');
  const volume = $('sfx-volume');
  toggle.checked = localStorage.getItem(SFX_ON_KEY) !== 'false';
  volume.value = localStorage.getItem(SFX_VOL_KEY) || '60';
  toggle.onchange = () => localStorage.setItem(SFX_ON_KEY, toggle.checked);
  volume.oninput = () => localStorage.setItem(SFX_VOL_KEY, volume.value);
  $('settings-btn').onclick = () => $('settings').classList.remove('hidden');
  $('settings-close').onclick = () => $('settings').classList.add('hidden');
}
initSettings();

const modeSelect = $('mode-select');
const gameEl = $('game');
const endEl = $('end');
const quoteEl = $('quote');
const optionsEl = $('options');
const feedbackEl = $('feedback');
const timerRing = $('timer-ring');
const ringFg = $('ring-fg');
const timerNum = $('timer-num');
const genreBadge = $('genre-badge');
const promptEl = $('prompt');

const GENRES = {
  action: { color: 'var(--g-action)', text: 'var(--g-action-text)' },
  comedy: { color: 'var(--g-comedy)', text: 'var(--g-comedy-text)' },
  drama: { color: 'var(--g-drama)', text: 'var(--g-drama-text)' },
  scifi: { color: 'var(--g-scifi)', text: 'var(--g-scifi-text)' },
  classic: { color: 'var(--g-classic)', text: 'var(--g-classic-text)' },
  pop: { color: 'var(--g-pop)', text: 'var(--g-pop-text)' },
  rock: { color: 'var(--g-rock)', text: 'var(--g-rock-text)' },
  hiphop: { color: 'var(--g-hiphop)', text: 'var(--g-hiphop-text)' },
  rnb: { color: 'var(--g-rnb)', text: 'var(--g-rnb-text)' },
  country: { color: 'var(--g-country)', text: 'var(--g-country-text)' },
};

fetch('quotes.json').then(r => r.json()).then(data => {
  quotes = data;
  const genreSelect = $('genre');
  [...new Set(data.map(q => q.genre))].sort().forEach(g => {
    const opt = document.createElement('option');
    opt.value = g;
    opt.textContent = g[0].toUpperCase() + g.slice(1);
    genreSelect.appendChild(opt);
  });
  buildBackdrop(data);
});

// Static mosaic of the bank's artwork behind the game. Reuses the fetch above rather than
// pulling quotes.json twice, and asks for thumbnails, not the full-size art flashArt() uses.
function buildBackdrop(data) {
  const el = $('backdrop');
  if (!el) return;
  const seen = new Set();
  const art = [];
  data.forEach(q => {
    if (!q.art || seen.has(q.art)) return;
    seen.add(q.art);
    art.push({
      url: q.art.replace('/w500/', '/w185/').replace('/600x600bb.jpg', '/200x200bb.jpg'),
      sq: q.type === 'music',
    });
  });
  if (art.length < 8) return;
  const shuffled = shuffle(art);
  const cols = Math.max(3, Math.ceil(window.innerWidth / 150));
  const per = Math.ceil(window.innerHeight / 150) + 1;
  for (let c = 0; c < cols; c++) {
    const col = document.createElement('div');
    col.className = 'bcol';
    for (let r = 0; r < per; r++) {
      const a = shuffled[(c * per + r) % shuffled.length];
      const img = new Image();
      img.src = a.url;
      img.alt = '';
      img.referrerPolicy = 'no-referrer';
      if (a.sq) img.className = 'sq';
      col.appendChild(img);
    }
    el.appendChild(col);
  }
}

function shuffle(arr) {
  return [...arr].sort(() => Math.random() - 0.5);
}

function startGame(speed) {
  speedMode = speed;
  score = 0;
  streak = 0;
  const genre = $('genre').value;
  pool = shuffle(genre === 'all' ? quotes : quotes.filter(q => q.genre === genre));
  updateStats();
  modeSelect.classList.add('hidden');
  endEl.classList.add('hidden');
  gameEl.classList.remove('hidden');
  timerRing.classList.toggle('hidden', !speed);
  nextQuestion();
}

function nextQuestion() {
  clearInterval(timer);
  if (pool.length === 0) return endGame();
  current = pool.pop();
  const g = GENRES[current.genre] || { color: 'var(--accent)', text: '#fff' };
  genreBadge.textContent = current.genre;
  genreBadge.style.background = g.color;
  genreBadge.style.setProperty('--badge-text', g.text);
  quoteEl.textContent = `"${current.quote}"`;
  quoteEl.style.animation = 'none';
  void quoteEl.offsetWidth;
  quoteEl.style.animation = '';
  feedbackEl.textContent = '';
  optionsEl.innerHTML = '';
  promptEl.textContent = current.type === 'music' ? 'Guess the artist from the lyric.' : 'Guess the movie from the quote.';
  shuffle(current.options).forEach(opt => {
    const btn = document.createElement('button');
    btn.textContent = opt;
    btn.onclick = () => choose(opt, btn);
    optionsEl.appendChild(btn);
  });
  preloadArt(current.art);
  if (speedMode) startTimer();
}

function startTimer() {
  timeLeft = TIME_LIMIT;
  updateRing();
  timer = setInterval(() => {
    timeLeft -= 0.1;
    updateRing();
    if (timeLeft <= 0) {
      clearInterval(timer);
      choose(null, null);
    }
  }, 100);
}

function updateRing() {
  const pct = Math.max(0, timeLeft / TIME_LIMIT) * 100;
  ringFg.style.strokeDasharray = `${pct} 100`;
  timerNum.textContent = Math.ceil(timeLeft);
}

function choose(opt, btn) {
  clearInterval(timer);
  const correct = opt === current.answer;
  [...optionsEl.children].forEach(b => {
    if (b.textContent === current.answer) b.classList.add('correct');
    else if (b === btn) b.classList.add('wrong');
    b.disabled = true;
  });
  if (correct) {
    flashArt(current.art);
    streak++;
    const bonus = speedMode ? Math.max(1, Math.ceil(timeLeft)) : 1;
    score += 10 * bonus;
    feedbackEl.textContent = `Correct! +${10 * bonus}`;
    beep(660, 0.15);
  } else {
    streak = 0;
    feedbackEl.textContent = `Nope — it was "${current.answer}"`;
    beep(180, 0.25);
  }
  updateStats();
  setTimeout(nextQuestion, 1100);
}

// Full-size art is fetched as soon as the question is shown, so a correct answer flashes
// it instantly instead of racing a cold network fetch against the 1100ms round timer.
const artCache = new Map();
function preloadArt(url) {
  if (!url || artCache.has(url)) return;
  const img = new Image();
  img.referrerPolicy = 'no-referrer';
  artCache.set(url, img);
  img.src = url;
}

let artEl = null;
let artHideTimer = null;
function flashArt(url) {
  if (!url) return;
  if (!artEl) {
    artEl = document.createElement('div');
    artEl.id = 'art-flash';
    document.body.appendChild(artEl);
  }
  const show = () => {
    // Back-to-back correct answers: kill the previous hide so it can't cut this one short.
    clearTimeout(artHideTimer);
    artEl.style.backgroundImage = `url("${url}")`;
    artEl.classList.add('show');
    artHideTimer = setTimeout(() => artEl.classList.remove('show'), 950);
  };
  const cached = artCache.get(url);
  if (cached && cached.complete && cached.naturalWidth) return show();
  // Still in flight. Show it when it lands, but only if this question is still on screen —
  // otherwise it flashes the previous round's art over the next quote. A failed load is a
  // no-op rather than a stuck overlay.
  const asked = current;
  const img = new Image();
  img.referrerPolicy = 'no-referrer';
  img.onload = () => { if (current === asked) show(); };
  img.src = url;
}

function updateStats() {
  $('score').textContent = `Score: ${score}`;
  $('streak').textContent = `Streak: ${streak}`;
}

function endGame() {
  gameEl.classList.add('hidden');
  endEl.classList.remove('hidden');
  const high = Math.max(score, parseInt(localStorage.getItem(HIGH_KEY) || '0', 10));
  localStorage.setItem(HIGH_KEY, high);
  $('final-score').textContent = `Final score: ${score} · High score: ${high}`;
  window.quotableSubmitScore?.(score, speedMode ? 'speed' : 'normal');
}

const showLeaderboard = () => {
  $('leaderboard').classList.remove('hidden');
  window.quotableShowLeaderboard?.(speedMode ? 'speed' : 'normal');
};
$('lb-btn').onclick = showLeaderboard;
$('lb-btn-end').onclick = showLeaderboard;
$('lb-close').onclick = () => $('leaderboard').classList.add('hidden');

$('start-normal').onclick = () => startGame(false);
$('start-speed').onclick = () => startGame(true);
$('restart').onclick = () => {
  endEl.classList.add('hidden');
  modeSelect.classList.remove('hidden');
};
$('share').onclick = () => {
  const text = `I scored ${score} on Quotestreak! Can you beat me? https://quotable.heyitsmejosh.com`;
  if (navigator.share) navigator.share({ text });
  else navigator.clipboard.writeText(text).then(() => {
    $('share').textContent = 'Copied!';
    setTimeout(() => { $('share').textContent = 'Share Score'; }, 1500);
  });
};

// Exports for webmcp.js — read-only accessors + the existing handlers themselves.
window.quotableStartGame = startGame;
window.quotableChoose = choose;
window.quotableNextQuestion = nextQuestion;
window.quotableSetGenre = (genre) => { $('genre').value = genre; };
window.quotableGetState = () => ({
  inProgress: !gameEl.classList.contains('hidden'),
  speedMode,
  score,
  streak,
  genre: $('genre').value,
  question: current ? {
    genre: current.genre,
    type: current.type,
    quote: current.quote,
    options: current.options,
  } : null,
});
window.quotableGetHighScore = () => parseInt(localStorage.getItem(HIGH_KEY) || '0', 10);
