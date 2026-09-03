// Accounts + leaderboard on the shared spark Supabase project. Vanilla, no bundler.
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const sb = createClient(
  'https://tjsxsqlxjmanwvmywwvw.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqc3hzcWx4am1hbnd2bXl3d3Z3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA0OTc0MDEsImV4cCI6MjA4NjA3MzQwMX0.LphLfho3wdQC20MhtcnBpzQUNuBoTOobrugQbNGxc68'
);
const $ = (id) => document.getElementById(id);
let user = null;

const displayName = (u) =>
  u.user_metadata?.name || u.user_metadata?.full_name || u.email?.split('@')[0] || 'Player';

function render() {
  $('account-btn').textContent = user ? displayName(user) : 'Sign in';
  $('auth-form').classList.toggle('hidden', !!user);
  $('auth-signed').classList.toggle('hidden', !user);
  if (user) $('auth-who').textContent = `Signed in as ${displayName(user)}`;
}

sb.auth.onAuthStateChange((_e, session) => { user = session?.user ?? null; render(); });

const msg = (t) => { $('auth-msg').textContent = t; };

$('account-btn').onclick = () => $('account').classList.toggle('hidden');
$('account-close').onclick = () => $('account').classList.add('hidden');

$('auth-login').onclick = async () => {
  const { error } = await sb.auth.signInWithPassword({ email: $('auth-email').value, password: $('auth-pass').value });
  msg(error ? error.message : '');
};
$('auth-signup').onclick = async () => {
  const { error } = await sb.auth.signUp({
    email: $('auth-email').value,
    password: $('auth-pass').value,
    options: { data: { name: $('auth-name').value.trim().slice(0, 24) || undefined }, emailRedirectTo: location.origin + '/play' },
  });
  msg(error ? error.message : 'Check your email to confirm your account.');
};
$('auth-google').onclick = () =>
  sb.auth.signInWithOAuth({ provider: 'google', options: { redirectTo: location.origin + '/play' } });
$('auth-apple').onclick = () =>
  sb.auth.signInWithOAuth({ provider: 'apple', options: { redirectTo: location.origin + '/play' } });
$('auth-logout').onclick = () => sb.auth.signOut();

// Called by game.js at game over. Silently no-ops when signed out.
window.quotableSubmitScore = async (score, mode) => {
  if (!user || score <= 0) return;
  await sb.from('quotestreak_scores').insert({ user_id: user.id, name: displayName(user).slice(0, 24), score, mode });
};

window.quotableShowLeaderboard = async (mode) => {
  const { data, error } = await sb.from('quotestreak_leaderboard')
    .select('name,score').eq('mode', mode).order('score', { ascending: false }).limit(20);
  const ol = $('lb-list');
  ol.innerHTML = '';
  if (error) { ol.innerHTML = `<li>${error.message}</li>`; return; }
  if (!data.length) ol.innerHTML = '<li>No scores yet. Sign in and play!</li>';
  for (const r of data) {
    const li = document.createElement('li');
    li.textContent = `${r.name} — ${r.score}`;
    ol.appendChild(li);
  }
  $('lb-title').textContent = mode === 'speed' ? 'Speed Round leaders' : 'Leaders';
};
