#!/bin/bash

cat > /c/Users/oneil/Desktop/paddle/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Paddle Tennis Performance Analyzer</title>
<style>
:root {
  --primary: #1a2a4a; --accent: #00c97d; --surface: #f0f4f8;
  --card-bg: #fff; --text: #1a2a4a; --text-muted: #6b7a99;
  --border: #e2e8f0; --shadow: 0 2px 8px rgba(26,42,74,.10);
  --shadow-hover: 0 8px 24px rgba(26,42,74,.18);
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: var(--surface); color: var(--text); min-height: 100vh; }

/* Header */
header { background: var(--primary); color: #fff; padding: 20px 32px 0; position: sticky; top: 0; z-index: 100; box-shadow: 0 2px 12px rgba(0,0,0,.25); }
.header-img { position: absolute; right: 16px; top: 0; bottom: 36px; height: 80px; width: auto; margin: auto; object-fit: contain; border-radius: 6px; opacity: .92; }
.header-row { display: flex; align-items: flex-end; gap: 20px; flex-wrap: wrap; margin-bottom: 12px; }
header h1 { font-size: 1.5rem; font-weight: 700; letter-spacing: -.5px; }
header h1 span { color: var(--accent); }
.header-sub { font-size: .78rem; color: rgba(255,255,255,.5); text-transform: uppercase; letter-spacing: .5px; margin-bottom: 2px; }
.search-wrap { margin-left: auto; position: relative; }
#searchInput { background: rgba(255,255,255,.1); border: 1px solid rgba(255,255,255,.2); border-radius: 8px; color: #fff; font-size: .88rem; padding: 7px 12px 7px 34px; outline: none; width: 210px; transition: background .2s, border .2s; }
#searchInput::placeholder { color: rgba(255,255,255,.4); }
#searchInput:focus { background: rgba(255,255,255,.16); border-color: var(--accent); }
.search-icon { position: absolute; left: 9px; top: 50%; transform: translateY(-50%); opacity: .5; pointer-events: none; }
.header-info { font-size: .78rem; color: rgba(255,255,255,.55); padding: 4px 0 10px; }
.header-info span { color: var(--accent); font-weight: 600; }

/* Top-level Tabs */
.tabs { display: flex; gap: 0; border-top: 1px solid rgba(255,255,255,.12); margin-top: 4px; }
.tab-btn { background: none; border: none; color: rgba(255,255,255,.55); font-size: .88rem; font-weight: 500; padding: 10px 22px; cursor: pointer; border-bottom: 3px solid transparent; transition: color .15s, border-color .15s; white-space: nowrap; }
.tab-btn:hover { color: #fff; }
.tab-btn.active { color: #fff; border-bottom-color: var(--accent); }

/* Tab content */
.tab-pane { display: none; }
.tab-pane.active { display: block; }

/* ── SW TEAM RATINGS ── */
#swPane { padding: 24px 32px; }
.sw-division { background: var(--card-bg); border-radius: 12px; box-shadow: var(--shadow); margin-bottom: 16px; overflow: hidden; }
.sw-div-header { background: var(--primary); border-top: 4px solid var(--accent); padding: 14px 18px; cursor: pointer; display: flex; align-items: center; gap: 10px; user-select: none; }
.sw-div-header:hover { filter: brightness(1.12); }
.sw-div-title { color: #fff; font-size: 1rem; font-weight: 700; flex: 1; }
.sw-div-chevron { color: rgba(255,255,255,.6); font-size: .8rem; transition: transform .2s; }
.sw-division.open .sw-div-chevron { transform: rotate(90deg); }
.sw-div-body { display: none; }
.sw-division.open .sw-div-body { display: block; }

/* Team rows */
.sw-team { border-bottom: 1px solid var(--border); }
.sw-team:last-child { border-bottom: none; }
.sw-team-header { display: flex; align-items: center; gap: 0; padding: 11px 18px; cursor: pointer; background: var(--card-bg); transition: background .15s; }
.sw-team-header:hover { background: #f6f9fd; }
.sw-team.open .sw-team-header { background: #f0f5ff; }
.sw-team-chevron { color: var(--text-muted); font-size: .72rem; width: 16px; transition: transform .2s; flex-shrink: 0; }
.sw-team.open .sw-team-chevron { transform: rotate(90deg); }
.sw-team-place { font-size: .72rem; font-weight: 700; color: #fff; background: var(--primary); border-radius: 50%; width: 22px; height: 22px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; margin-right: 10px; }
.sw-team-place.p1 { background: #d4a017; }
.sw-team-place.p2 { background: #8a9bb0; }
.sw-team-place.p3 { background: #a0714f; }
.sw-team-name { font-size: .9rem; font-weight: 600; flex: 1; min-width: 0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.sw-team-stats { display: flex; gap: 20px; flex-shrink: 0; font-size: .78rem; color: var(--text-muted); }
.sw-stat { text-align: right; }
.sw-stat-val { display: block; font-size: .88rem; font-weight: 700; color: var(--text); }
.sw-stat-lbl { display: block; font-size: .68rem; text-transform: uppercase; letter-spacing: .4px; }

/* Team body with sub-tabs */
.sw-team-body { display: none; background: #fafbfd; }
.sw-team.open .sw-team-body { display: block; }

/* Sub-tabs inside team body */
.team-subtabs { display: flex; border-bottom: 2px solid var(--border); background: #f0f4f8; padding: 0 18px; }
.team-subtab { background: none; border: none; border-bottom: 2px solid transparent; margin-bottom: -2px; color: var(--text-muted); font-size: .78rem; font-weight: 600; padding: 8px 14px; cursor: pointer; text-transform: uppercase; letter-spacing: .4px; transition: color .15s, border-color .15s; }
.team-subtab:hover { color: var(--text); }
.team-subtab.active { color: var(--primary); border-bottom-color: var(--accent); }
.team-subpane { display: none; }
.team-subpane.active { display: block; }

/* Player table */
.sw-players-table { width: 100%; border-collapse: collapse; font-size: .82rem; }
.sw-players-table th { background: #eef2f8; color: var(--text-muted); font-size: .68rem; font-weight: 600; text-transform: uppercase; letter-spacing: .4px; padding: 7px 18px; text-align: left; border-bottom: 1px solid var(--border); }
.sw-players-table th:last-child, .sw-players-table td:last-child { text-align: right; padding-right: 18px; }
.sw-players-table td { padding: 7px 18px; border-bottom: 1px solid var(--border); color: var(--text); }
.sw-players-table tr:last-child td { border-bottom: none; }
.sw-players-table tr:hover td { background: #f0f4fa; }
.pti-badge { display: inline-block; font-size: .75rem; font-weight: 700; padding: 2px 7px; border-radius: 20px; background: var(--surface); color: var(--text-muted); }

/* Analysis tables (line / partner) */
.analysis-table { width: 100%; border-collapse: collapse; font-size: .82rem; }
.analysis-table th { background: #eef2f8; color: var(--text-muted); font-size: .68rem; font-weight: 600; text-transform: uppercase; letter-spacing: .4px; padding: 7px 18px; text-align: left; border-bottom: 1px solid var(--border); }
.analysis-table td { padding: 7px 18px; border-bottom: 1px solid var(--border); color: var(--text); vertical-align: top; }
.analysis-table tr.drilldown-header { cursor: pointer; user-select: none; }
.analysis-table tr.drilldown-header:hover td { background: #f0f4fa; }
.analysis-table tr.drilldown-header td:first-child::before { content: '▶'; font-size: .6rem; color: var(--text-muted); margin-right: 6px; display: inline-block; transition: transform .15s; }
.analysis-table tr.drilldown-header.open td:first-child::before { transform: rotate(90deg); }
.analysis-table tr.drilldown-body { display: none; }
.analysis-table tr.drilldown-body.open { display: table-row; }
.drilldown-body td { background: #f8faff; padding: 0 18px 8px 34px; }
.drilldown-inner { border: 1px solid var(--border); border-radius: 6px; overflow: hidden; margin: 6px 0; font-size: .78rem; }
.drilldown-inner table { width: 100%; border-collapse: collapse; }
.drilldown-inner td { padding: 5px 12px; border-bottom: 1px solid var(--border); color: var(--text-muted); }
.drilldown-inner tr:last-child td { border-bottom: none; }
.drilldown-inner tr:hover td { background: #eef2f8; }
.wl-badge { display: inline-block; font-size: .72rem; font-weight: 700; padding: 1px 8px; border-radius: 20px; }
.wl-win  { background: rgba(0,201,125,.12); color: #00845a; }
.wl-loss { background: rgba(229,62,62,.10); color: #c53030; }
.wl-neutral { background: var(--surface); color: var(--text-muted); }

/* Stat label tooltips */
.sw-stat-lbl[title] { cursor: help; border-bottom: 1px dotted var(--text-muted); }

/* Release Notes & Feedback panes */
.static-pane { max-width: 680px; margin: 40px auto; background: var(--card-bg); border-radius: 12px; box-shadow: var(--shadow); padding: 36px 40px; }
.static-pane h2 { font-size: 1.15rem; font-weight: 700; color: var(--primary); margin-bottom: 20px; border-bottom: 2px solid var(--accent); padding-bottom: 10px; }
.static-pane p { font-size: .88rem; color: var(--text); line-height: 1.7; margin-bottom: 14px; }
.static-pane a { color: var(--accent); text-decoration: none; font-weight: 600; }
.static-pane a:hover { text-decoration: underline; }
.static-pane .version { font-size: .75rem; color: var(--text-muted); margin-bottom: 18px; }

/* Feedback / comments */
.fb-form { display: flex; flex-direction: column; gap: 12px; margin-bottom: 32px; }
.fb-form label { font-size: .78rem; font-weight: 600; color: var(--text-muted); text-transform: uppercase; letter-spacing: .4px; display: block; margin-bottom: 3px; }
.fb-form input, .fb-form textarea { width: 100%; padding: 9px 12px; border: 1px solid var(--border); border-radius: 8px; font-size: .88rem; font-family: inherit; color: var(--text); background: var(--surface); outline: none; transition: border-color .15s; }
.fb-form input:focus, .fb-form textarea:focus { border-color: var(--accent); }
.fb-form textarea { min-height: 100px; resize: vertical; }
.fb-submit { background: var(--primary); color: #fff; border: none; border-radius: 8px; padding: 9px 26px; font-size: .88rem; font-weight: 600; cursor: pointer; align-self: flex-start; transition: background .15s; }
.fb-submit:hover { background: #243d6a; }
.fb-submit:disabled { opacity: .6; cursor: default; }
.comments-list { display: flex; flex-direction: column; gap: 14px; }
.comment-card { background: var(--surface); border: 1px solid var(--border); border-radius: 10px; padding: 14px 18px; }
.comment-meta { font-size: .72rem; color: var(--text-muted); margin-bottom: 6px; }
.comment-name { font-weight: 700; color: var(--primary); margin-right: 8px; }
.comment-text { font-size: .88rem; color: var(--text); line-height: 1.6; white-space: pre-wrap; }
.comments-empty { font-size: .88rem; color: var(--text-muted); font-style: italic; text-align: center; padding: 20px 0; }
.fb-notice { font-size: .78rem; color: var(--text-muted); margin-top: 4px; }

.no-data { padding: 16px 18px; color: var(--text-muted); font-size: .82rem; font-style: italic; }

/* ── PLAYER RATINGS (Tab 2) ── */
#prPane { padding: 24px 32px; }
#clubGrid { display: grid; grid-template-columns: repeat(3,1fr); gap: 20px; }
.club-card { background: var(--card-bg); border-radius: 12px; box-shadow: var(--shadow); overflow: hidden; transition: transform .2s, box-shadow .2s; display: flex; flex-direction: column; }
.club-card:hover { transform: translateY(-3px); box-shadow: var(--shadow-hover); }
.club-card[data-hidden="true"] { display: none; }
.card-header { background: var(--primary); border-top: 4px solid var(--accent); padding: 13px 16px 9px; }
.card-header h3 { font-size: .92rem; font-weight: 600; color: #fff; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.card-header h3 a { color: #fff; text-decoration: none; cursor: pointer; }
.card-header h3 a:hover { color: var(--accent); }
.card-body { padding: 10px 16px; flex: 1; }
.player-row { display: flex; align-items: center; gap: 8px; padding: 5px 0; border-bottom: 1px solid var(--border); font-size: .84rem; }
.player-row:last-child { border-bottom: none; }
.rank { font-size: .68rem; font-weight: 700; color: var(--text-muted); min-width: 16px; text-align: center; }
.rank.top { color: var(--accent); }
.player-info { flex: 1; min-width: 0; }
.player-name { font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: block; }
.player-team { font-size: .7rem; color: var(--text-muted); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: block; margin-top: 1px; }
.rating-badge { font-size: .73rem; font-weight: 700; padding: 2px 7px; border-radius: 20px; white-space: nowrap; }
.rating-badge.best { background: rgba(0,201,125,.12); color: #00a065; }
.rating-badge.normal { background: var(--surface); color: var(--text-muted); }
.card-footer { padding: 7px 16px; background: var(--surface); font-size: .72rem; color: var(--text-muted); border-top: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; }

/* Modal */
#modal { display: none; position: fixed; inset: 0; z-index: 1000; background: rgba(10,20,40,.65); backdrop-filter: blur(4px); align-items: center; justify-content: center; padding: 20px; }
#modal.open { display: flex; }
.modal-panel { background: var(--card-bg); border-radius: 16px; box-shadow: 0 24px 80px rgba(0,0,0,.35); max-width: 780px; width: 100%; max-height: 85vh; display: flex; flex-direction: column; animation: modalIn .22s ease; }
@keyframes modalIn { from { transform: scale(.94) translateY(10px); opacity: 0; } to { transform: scale(1) translateY(0); opacity: 1; } }
.modal-header { background: var(--primary); border-top: 4px solid var(--accent); border-radius: 12px 12px 0 0; padding: 16px 20px; display: flex; align-items: center; justify-content: space-between; flex-shrink: 0; }
.modal-header h2 { color: #fff; font-size: 1rem; font-weight: 600; }
.modal-close { background: rgba(255,255,255,.12); border: none; color: #fff; width: 28px; height: 28px; border-radius: 50%; font-size: .95rem; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: background .15s; }
.modal-close:hover { background: rgba(255,255,255,.22); }
.modal-body { overflow-y: auto; flex: 1; }
.modal-table { width: 100%; border-collapse: collapse; font-size: .83rem; }
.modal-table thead th { position: sticky; top: 0; background: var(--surface); color: var(--text-muted); font-size: .7rem; font-weight: 600; text-transform: uppercase; letter-spacing: .4px; padding: 9px 14px; text-align: left; border-bottom: 2px solid var(--border); white-space: nowrap; }
.modal-table thead th:first-child { text-align: center; }
.modal-table thead th.sortable { cursor: pointer; }
.modal-table thead th.sortable:hover { color: var(--primary); }
.modal-table thead th.sort-asc::after { content: ' ▲'; font-size: .6rem; }
.modal-table thead th.sort-desc::after { content: ' ▼'; font-size: .6rem; }
.modal-table tbody tr:hover { background: #f8fafc; }
.modal-table td { padding: 8px 14px; border-bottom: 1px solid var(--border); }
.modal-table td:first-child { text-align: center; font-size: .75rem; font-weight: 700; color: var(--text-muted); width: 36px; }
.modal-table tr:first-child td:first-child { color: var(--accent); }
.modal-footer { padding: 10px 20px; background: var(--surface); border-radius: 0 0 12px 12px; font-size: .75rem; color: var(--text-muted); border-top: 1px solid var(--border); flex-shrink: 0; }
.div-badge { font-size: .68rem; background: rgba(26,42,74,.08); color: var(--text-muted); padding: 1px 6px; border-radius: 4px; }
.diff-pos { color: #e53e3e; }
.diff-neg { color: #00a065; }

@media (max-width: 900px) {
  #clubGrid { grid-template-columns: repeat(2,1fr); }
  #swPane, #prPane { padding: 16px; }
  header { padding: 14px 16px 0; }
  .sw-team-stats { gap: 12px; }
}
@media (max-width: 560px) {
  #clubGrid { grid-template-columns: 1fr; }
  header h1 { font-size: 1.2rem; }
  #searchInput { width: 140px; }
  .sw-team-stats { display: none; }
}
</style>
</head>
<body>

<header>
  <div class="header-row">
    <div>
      <div class="header-sub">APTA Chicago</div>
      <h1>Paddle Tennis <span>Performance</span> Analyzer</h1>
    </div>
    <div class="search-wrap" id="searchWrap" style="display:none">
      <svg class="search-icon" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
      <input id="searchInput" type="text" placeholder="Search locations..." autocomplete="off">
    </div>
  </div>
  <img class="header-img" src="paddlegangster.png" alt="">
  <div class="header-info" id="headerInfo"></div>
  <nav class="tabs">
    <button class="tab-btn active" data-tab="sw">SW Series Stats</button>
    <button class="tab-btn" data-tab="ts">Top Series Stats</button>
    <button class="tab-btn" data-tab="pr">Player Ratings</button>
    <button class="tab-btn" data-tab="hl">Helpful Links</button>
    <button class="tab-btn" data-tab="rn">Release Notes</button>
    <button class="tab-btn" data-tab="fb">Feedback</button>
  </nav>
</header>

<div id="swPane" class="tab-pane active"></div>
<div id="tsPane" class="tab-pane"></div>
<div id="prPane" class="tab-pane">
  <div id="clubGrid"></div>
</div>
<div id="hlPane" class="tab-pane"></div>
<div id="rnPane" class="tab-pane"></div>
<div id="fbPane" class="tab-pane"></div>

<div id="modal" role="dialog" aria-modal="true">
  <div class="modal-panel">
    <div class="modal-header">
      <h2 id="modalTitle">Location</h2>
      <button class="modal-close" id="modalClose">&#x2715;</button>
    </div>
    <div class="modal-body" id="modalBody"></div>
    <div class="modal-footer" id="modalFooter"></div>
  </div>
</div>

<script>
// ── Data ──────────────────────────────────────────────────────
HTMLEOF

# Inject data by catting files directly — avoids shell interpretation of special chars
{
  printf 'const SW_DATA = '
  cat /c/Users/oneil/Desktop/paddle/sw_data.json
  printf ';\nconst PLAYER_DATA = '
  cat /c/Users/oneil/Desktop/paddle/data.json
  printf ';\nconst MATCH_DATA = '
  if [ -f /c/Users/oneil/Desktop/paddle/match_data.json ]; then
    cat /c/Users/oneil/Desktop/paddle/match_data.json
  else
    printf '[]'
  fi
  printf ';\nconst TOP_DATA = '
  if [ -f /c/Users/oneil/Desktop/paddle/top_data.json ]; then
    cat /c/Users/oneil/Desktop/paddle/top_data.json
  else
    printf '[]'
  fi
  printf ';\nconst TOP_MATCH_DATA = '
  if [ -f /c/Users/oneil/Desktop/paddle/top_match_data.json ]; then
    cat /c/Users/oneil/Desktop/paddle/top_match_data.json
  else
    printf '[]'
  fi
  printf ';\n'
} >> /c/Users/oneil/Desktop/paddle/index.html

cat >> /c/Users/oneil/Desktop/paddle/index.html << 'HTMLEOF'

try {

PLAYER_DATA.forEach(loc => loc.players.forEach(p => {
  if (!Array.isArray(p.teamNames)) p.teamNames = p.teamNames ? [p.teamNames] : [];
}));

// Index MATCH_DATA by team name for quick lookup
const matchByTeam = {};
MATCH_DATA.forEach(m => {
  [m.team1, m.team2].forEach(t => {
    if (!matchByTeam[t]) matchByTeam[t] = [];
    matchByTeam[t].push(m);
  });
});

// ── Utilities ─────────────────────────────────────────────────
function esc(s) {
  return String(s)
    .replace(/[\u2018\u2019\u02BC]/g, "'")
    .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
    .replace(/"/g,'&quot;').replace(/'/g,'&#39;');
}
function fmtR(v) {
  if (v === null || v === undefined || isNaN(v)) return '-';
  return v > 0 ? '+' + v.toFixed(2) : v.toFixed(2);
}
function diffCls(v) { return !v || v===0 ? '' : v<0 ? 'diff-neg' : 'diff-pos'; }
function lastName(full) { return full ? full.trim().split(/\s+/).pop() : ''; }
function pairKey(pair) { return pair.map(lastName).sort().join(' / '); }
function wlHtml(w, l) {
  const t = w + l;
  const cls = t === 0 ? 'wl-neutral' : (w > l ? 'wl-win' : w < l ? 'wl-loss' : 'wl-neutral');
  return '<span class="wl-badge ' + cls + '">' + w + 'W / ' + l + 'L</span>';
}

// ── Tab switching ─────────────────────────────────────────────
const topTabs = document.querySelectorAll('.tab-btn');
const panes = { sw: document.getElementById('swPane'), ts: document.getElementById('tsPane'), pr: document.getElementById('prPane'), hl: document.getElementById('hlPane'), rn: document.getElementById('rnPane'), fb: document.getElementById('fbPane') };
const searchWrap = document.getElementById('searchWrap');
const headerInfo = document.getElementById('headerInfo');

topTabs.forEach(btn => btn.addEventListener('click', () => {
  topTabs.forEach(b => b.classList.remove('active'));
  Object.values(panes).forEach(p => p.classList.remove('active'));
  btn.classList.add('active');
  const tab = btn.dataset.tab;
  panes[tab].classList.add('active');
  searchWrap.style.display = tab === 'pr' ? '' : 'none';
  updateHeaderInfo(tab);
}));

function updateHeaderInfo(tab) {
  if (tab === 'sw') {
    const teams = SW_DATA.reduce((s,d) => s + d.teams.length, 0);
    const players = SW_DATA.reduce((s,d) => s + d.teams.reduce((t,tm) => t + (Array.isArray(tm.players) ? tm.players.length : 0), 0), 0);
    const matchStr = MATCH_DATA.length > 0 ? ' &nbsp;|&nbsp; Matches: <span>' + MATCH_DATA.length + '</span>' : '';
    headerInfo.innerHTML = 'SW divisions: <span>' + SW_DATA.length + '</span> &nbsp;|&nbsp; Teams: <span>' + teams + '</span> &nbsp;|&nbsp; Players: <span>' + players.toLocaleString() + '</span>' + matchStr;
  } else if (tab === 'ts') {
    const teams = TOP_DATA.reduce((s,d) => s + d.teams.length, 0);
    const players = TOP_DATA.reduce((s,d) => s + d.teams.reduce((t,tm) => t + (Array.isArray(tm.players) ? tm.players.length : 0), 0), 0);
    const matchStr = TOP_MATCH_DATA.length > 0 ? ' &nbsp;|&nbsp; Matches: <span>' + TOP_MATCH_DATA.length + '</span>' : '';
    headerInfo.innerHTML = 'Divisions: <span>' + TOP_DATA.length + '</span> &nbsp;|&nbsp; Teams: <span>' + teams + '</span> &nbsp;|&nbsp; Players: <span>' + players.toLocaleString() + '</span>' + matchStr;
  } else if (tab === 'pr') {
    const total = PLAYER_DATA.reduce((s,l) => s+l.players.length, 0);
    headerInfo.innerHTML = 'Locations: <span>' + PLAYER_DATA.length + '</span> &nbsp;|&nbsp; Active players: <span>' + total.toLocaleString() + '</span>';
  } else {
    headerInfo.innerHTML = '';
  }
}

// ── SW TEAM RATINGS ───────────────────────────────────────────
const swPane = document.getElementById('swPane');

// Build name → current PTI lookup (for substitute player PTI fallback)
const playerPTIMap = {};
SW_DATA.forEach(div => div.teams.forEach(team => {
  if (!Array.isArray(team.players)) return;
  team.players.forEach(p => { if (!playerPTIMap[p.name]) playerPTIMap[p.name] = p.rating; });
}));
TOP_DATA.forEach(div => div.teams.forEach(team => {
  if (!Array.isArray(team.players)) return;
  team.players.forEach(p => { if (!playerPTIMap[p.name]) playerPTIMap[p.name] = p.rating; });
}));
PLAYER_DATA.forEach(loc => loc.players.forEach(p => {
  const fn = p.firstName + ' ' + p.lastName;
  if (!playerPTIMap[fn]) playerPTIMap[fn] = p.currentRating;
}));

// Compute Avg PTI/Game using match data (includes substitutes)
function computeAdjAvgPTIPerGame(teamName, fallback, mbt) {
  const matches = mbt[teamName] || [];
  if (matches.length === 0) return fallback;
  let wSum = 0, cnt = 0;
  matches.forEach(m => {
    const isT1 = (m.team1 === teamName);
    (m.lines || []).forEach(ln => {
      const ourPair = isT1 ? ln.pair1 : ln.pair2;
      const ourPTI  = Array.isArray(isT1 ? ln.pti1 : ln.pti2) ? (isT1 ? ln.pti1 : ln.pti2) : [];
      (ourPair || []).forEach((name, i) => {
        if (!name) return;
        const pti = (ourPTI[i] > 0) ? ourPTI[i] : (playerPTIMap[name] || 0);
        if (pti > 0) { wSum += pti; cnt++; }
      });
    });
  });
  return cnt > 0 ? Math.round(wSum / cnt * 100) / 100 : fallback;
}

// Build player → teams maps (one per series)
const swPlayerTeamMap = {};
SW_DATA.forEach(div => {
  div.teams.forEach(team => {
    if (team.name.startsWith('BYE') || !Array.isArray(team.players)) return;
    team.players.forEach(p => {
      if (!swPlayerTeamMap[p.name]) swPlayerTeamMap[p.name] = [];
      if (!swPlayerTeamMap[p.name].includes(team.name)) swPlayerTeamMap[p.name].push(team.name);
    });
  });
});
const topPlayerTeamMap = {};
TOP_DATA.forEach(div => {
  div.teams.forEach(team => {
    if (team.name.startsWith('BYE') || !Array.isArray(team.players)) return;
    team.players.forEach(p => {
      if (!topPlayerTeamMap[p.name]) topPlayerTeamMap[p.name] = [];
      if (!topPlayerTeamMap[p.name].includes(team.name)) topPlayerTeamMap[p.name].push(team.name);
    });
  });
});

// Index TOP_MATCH_DATA by team name
const topMatchByTeam = {};
TOP_MATCH_DATA.forEach(m => {
  [m.team1, m.team2].forEach(t => {
    if (!topMatchByTeam[t]) topMatchByTeam[t] = [];
    topMatchByTeam[t].push(m);
  });
});

// ── Analysis helpers ──────────────────────────────────────────

function buildLineStats(teamName, mbt) {
  const matches = mbt[teamName] || [];
  const stats = {}; // lineNum -> { wins, losses, pairs: { pairKey -> {wins,losses} } }
  matches.forEach(m => {
    const isT1 = (m.team1 === teamName);
    (m.lines || []).forEach(ln => {
      const ourPair = isT1 ? ln.pair1 : ln.pair2;
      const weWon   = isT1 ? (ln.winner === 1) : (ln.winner === 2);
      const n = ln.line;
      if (!stats[n]) stats[n] = { wins: 0, losses: 0, pairs: {} };
      if (weWon) stats[n].wins++; else stats[n].losses++;
      const pk = pairKey(ourPair);
      if (!stats[n].pairs[pk]) stats[n].pairs[pk] = { wins: 0, losses: 0 };
      if (weWon) stats[n].pairs[pk].wins++; else stats[n].pairs[pk].losses++;
    });
  });
  return stats;
}

function buildPartnerStats(teamName, mbt) {
  const matches = mbt[teamName] || [];
  const stats = {}; // pairKey -> { wins, losses, matches: [...] }
  matches.forEach(m => {
    const isT1 = (m.team1 === teamName);
    const opp  = isT1 ? m.team2 : m.team1;
    (m.lines || []).forEach(ln => {
      const ourPair = isT1 ? ln.pair1 : ln.pair2;
      const oppPair = isT1 ? ln.pair2 : ln.pair1;
      const weWon   = isT1 ? (ln.winner === 1) : (ln.winner === 2);
      const pk = pairKey(ourPair);
      if (!stats[pk]) stats[pk] = { wins: 0, losses: 0, matches: [] };
      if (weWon) stats[pk].wins++; else stats[pk].losses++;
      // Build set score string from line scores (e.g. "6-3, 7-5")
      const ourS  = Array.isArray(isT1 ? ln.scores1 : ln.scores2) ? (isT1 ? ln.scores1 : ln.scores2) : [];
      const theirS= Array.isArray(isT1 ? ln.scores2 : ln.scores1) ? (isT1 ? ln.scores2 : ln.scores1) : [];
      const numSets = Math.min(ourS.length, theirS.length);
      let lineScore = '';
      for (let s = 0; s < numSets; s++) { if (s) lineScore += ', '; lineScore += ourS[s] + '-' + theirS[s]; }
      stats[pk].matches.push({
        date: m.date,
        line: ln.line,
        opponent: opp,
        oppPair: oppPair.map(lastName).join(' / '),
        lineScore: lineScore || '-',
        won: weWon
      });
    });
  });
  return stats;
}

let _ddUid = 0;  // global counter — ensures every drilldown row has a unique DOM id

function renderLineAnalysis(teamName, mbt) {
  const stats = buildLineStats(teamName, mbt);
  const lines = Object.keys(stats).map(Number).sort((a,b) => a-b);
  if (lines.length === 0) return '<div class="no-data">No match data available for this team.</div>';

  let rows = '';
  lines.forEach(lineNum => {
    const ls = stats[lineNum];
    const id = 'dd-' + (_ddUid++);
    rows += '<tr class="drilldown-header" data-body="' + id + '">' +
      '<td><strong>Line ' + lineNum + '</strong></td>' +
      '<td>' + wlHtml(ls.wins, ls.losses) + '</td>' +
      '</tr>' +
      '<tr class="drilldown-body" id="' + id + '"><td colspan="2">' +
      '<div class="drilldown-inner"><table>';
    const pairs = Object.keys(ls.pairs).sort((a,b) => {
      const wa = ls.pairs[a].wins, la_ = ls.pairs[a].losses;
      const wb = ls.pairs[b].wins, lb_ = ls.pairs[b].losses;
      return (lb_ - wb) - (la_ - wa);
    });
    pairs.forEach(pk => {
      const ps = ls.pairs[pk];
      rows += '<tr><td>' + esc(pk) + '</td><td>' + wlHtml(ps.wins, ps.losses) + '</td></tr>';
    });
    rows += '</table></div></td></tr>';
  });

  return '<table class="analysis-table">' +
    '<thead><tr><th>Line</th><th>W / L</th></tr></thead>' +
    '<tbody>' + rows + '</tbody></table>';
}

function renderPartnerAnalysis(teamName, mbt) {
  const stats = buildPartnerStats(teamName, mbt);
  const pairs = Object.keys(stats).sort((a,b) => {
    const da = stats[a].wins - stats[a].losses;
    const db = stats[b].wins - stats[b].losses;
    return db - da;
  });
  if (pairs.length === 0) return '<div class="no-data">No match data available for this team.</div>';

  let rows = '';
  pairs.forEach(pk => {
    const ps = stats[pk];
    const id = 'dd-' + (_ddUid++);
    rows += '<tr class="drilldown-header" data-body="' + id + '">' +
      '<td><strong>' + esc(pk) + '</strong></td>' +
      '<td>' + wlHtml(ps.wins, ps.losses) + '</td>' +
      '</tr>' +
      '<tr class="drilldown-body" id="' + id + '"><td colspan="2">' +
      '<div class="drilldown-inner"><table>';
    ps.matches.sort((a,b) => (a.date > b.date ? -1 : 1)).forEach(mx => {
      const wonBadge = mx.won
        ? '<span style="color:#00845a;font-size:.7rem">&#10003;</span>'
        : '<span style="color:#c53030;font-size:.7rem">&#10007;</span>';
      rows += '<tr>' +
        '<td>' + wonBadge + ' ' + esc(mx.date || '') + '</td>' +
        '<td>Line ' + mx.line + '</td>' +
        '<td>' + esc(mx.opponent) + '</td>' +
        '<td>' + esc(mx.oppPair) + '</td>' +
        '<td>' + esc(mx.lineScore) + '</td>' +
        '</tr>';
    });
    rows += '</table></div></td></tr>';
  });

  return '<table class="analysis-table">' +
    '<thead><tr><th>Partners (last names)</th><th>W / L</th></tr></thead>' +
    '<tbody>' + rows + '</tbody></table>';
}

// Wire up drilldown click delegation
document.addEventListener('click', function(e) {
  const hdr = e.target.closest('tr.drilldown-header');
  if (!hdr) return;
  const bodyId = hdr.dataset.body;
  if (!bodyId) return;
  const body = document.getElementById(bodyId);
  if (!body) return;
  hdr.classList.toggle('open');
  body.classList.toggle('open');
});

// ── Shared series pane renderer ────────────────────────────────
function renderSeriesPane(data, paneEl, mbt, ptmMap) {
  data.forEach(div => {
    const allPlayers = div.teams.filter(t => !t.name.startsWith('BYE') && Array.isArray(t.players)).flatMap(t => t.players);
    const divAvgPTI = allPlayers.length > 0
      ? (allPlayers.reduce((s,p) => s + p.rating, 0) / allPlayers.length).toFixed(2) : '-';

    const divEl = document.createElement('div');
    divEl.className = 'sw-division';

    const hdr = document.createElement('div');
    hdr.className = 'sw-div-header';
    hdr.innerHTML = '<span class="sw-div-title">' + esc(div.division) + '</span>' +
      '<span style="color:rgba(255,255,255,.7);font-size:.8rem;margin-right:14px">Avg&nbsp;PTI:&nbsp;<strong style="color:var(--accent)">' + divAvgPTI + '</strong></span>' +
      '<span class="sw-div-chevron">&#9654;</span>';
    hdr.addEventListener('click', () => divEl.classList.toggle('open'));

    const body = document.createElement('div');
    body.className = 'sw-div-body';

    div.teams
      .filter(t => t.name !== 'BYE' && !t.name.startsWith('BYE'))
      .forEach(team => {
        const placeClass = team.place === 1 ? 'p1' : team.place === 2 ? 'p2' : team.place === 3 ? 'p3' : '';
        const teamEl = document.createElement('div');
        teamEl.className = 'sw-team';

        const thead = document.createElement('div');
        thead.className = 'sw-team-header';
        thead.innerHTML =
          '<span class="sw-team-chevron">&#9654;</span>' +
          '<span class="sw-team-place ' + placeClass + '">' + team.place + '</span>' +
          '<span class="sw-team-name">' + esc(team.name) + '</span>' +
          '<div class="sw-team-stats">' +
            '<div class="sw-stat"><span class="sw-stat-val">' + team.gamesRoster + '</span><span class="sw-stat-lbl" title="The number of series games played by rostered team members">Games/Roster</span></div>' +
            '<div class="sw-stat"><span class="sw-stat-val">' + team.avgPTI.toFixed(2) + '</span><span class="sw-stat-lbl" title="The average of final PTI of rostered team members">Avg. PTI</span></div>' +
            '<div class="sw-stat"><span class="sw-stat-val">' + computeAdjAvgPTIPerGame(team.name, team.avgPTIPerGame, mbt).toFixed(2) + '</span><span class="sw-stat-lbl" title="The average final PTI of players competing in matches (rostered players and subs)">PTI/Game</span></div>' +
          '</div>';
        thead.addEventListener('click', () => teamEl.classList.toggle('open'));

        const tbodyEl = document.createElement('div');
        tbodyEl.className = 'sw-team-body';

        const subTabBar = document.createElement('div');
        subTabBar.className = 'team-subtabs';

        const SUBTABS = [
          { id: 'players',  label: 'Players' },
          { id: 'lines',    label: 'Line Analysis' },
          { id: 'partners', label: 'Partner Analysis' },
        ];

        SUBTABS.forEach((st, i) => {
          const btn = document.createElement('button');
          btn.className = 'team-subtab' + (i === 0 ? ' active' : '');
          btn.textContent = st.label;
          btn.dataset.subtab = st.id;
          btn.addEventListener('click', e => {
            e.stopPropagation();
            const container = btn.closest('.sw-team-body');
            container.querySelectorAll('.team-subtab').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            container.querySelectorAll('.team-subpane').forEach(p => p.classList.remove('active'));
            container.querySelector('.team-subpane[data-pane="' + st.id + '"]').classList.add('active');
            const pane = container.querySelector('.team-subpane[data-pane="' + st.id + '"]');
            if (pane && pane.dataset.loaded !== 'true') {
              if (st.id === 'lines')    pane.innerHTML = renderLineAnalysis(team.name, mbt);
              if (st.id === 'partners') pane.innerHTML = renderPartnerAnalysis(team.name, mbt);
              pane.dataset.loaded = 'true';
            }
          });
          subTabBar.appendChild(btn);
        });
        tbodyEl.appendChild(subTabBar);

        const sorted = Array.isArray(team.players) ? [...team.players].sort((a,b) => a.rating - b.rating) : [];
        const playersPane = document.createElement('div');
        playersPane.className = 'team-subpane active';
        playersPane.dataset.pane = 'players';
        playersPane.dataset.loaded = 'true';
        playersPane.innerHTML =
          '<table class="sw-players-table">' +
          '<thead><tr><th>Player</th><th>Team(s)</th><th>Games</th><th>PTI</th></tr></thead><tbody>' +
          sorted.map(p => {
            const allTeams = ptmMap[p.name] || [team.name];
            const teamsHtml = allTeams.map(t => {
              const isCurrent = t === team.name;
              return '<span style="display:inline-block;font-size:.68rem;padding:1px 6px;border-radius:4px;margin:1px;background:' +
                (isCurrent ? 'rgba(26,42,74,.12);color:var(--text)' : 'rgba(0,201,125,.12);color:#00a065') + '">' + esc(t) + '</span>';
            }).join('');
            return '<tr><td>' + esc(p.name) + '</td>' +
              '<td>' + teamsHtml + '</td>' +
              '<td>' + p.games + ' <small style="color:var(--text-muted)">(' + p.wins + 'W&nbsp;/&nbsp;' + p.losses + 'L)</small></td>' +
              '<td style="text-align:right"><span class="pti-badge">' + p.rating.toFixed(1) + '</span></td></tr>';
          }).join('') +
          '</tbody></table>';
        tbodyEl.appendChild(playersPane);

        const linesPane = document.createElement('div');
        linesPane.className = 'team-subpane';
        linesPane.dataset.pane = 'lines';
        linesPane.innerHTML = '<div class="no-data">Click "Line Analysis" to load.</div>';
        tbodyEl.appendChild(linesPane);

        const partnersPane = document.createElement('div');
        partnersPane.className = 'team-subpane';
        partnersPane.dataset.pane = 'partners';
        partnersPane.innerHTML = '<div class="no-data">Click "Partner Analysis" to load.</div>';
        tbodyEl.appendChild(partnersPane);

        teamEl.appendChild(thead);
        teamEl.appendChild(tbodyEl);
        body.appendChild(teamEl);
      });

    divEl.appendChild(hdr);
    divEl.appendChild(body);
    paneEl.appendChild(divEl);
  });
}

// ── Build series panes ─────────────────────────────────────────
renderSeriesPane(SW_DATA,  document.getElementById('swPane'), matchByTeam,    swPlayerTeamMap);
renderSeriesPane(TOP_DATA, document.getElementById('tsPane'), topMatchByTeam, topPlayerTeamMap);

// ── PLAYER RATINGS (Tab 2) ────────────────────────────────────
const grid  = document.getElementById('clubGrid');
const modal = document.getElementById('modal');

const prData = PLAYER_DATA.filter(l => l.name !== 'BYE').sort((a,b) => a.name.localeCompare(b.name));

function renderCard(loc) {
  const sorted = [...loc.players].sort((a,b) => a.currentRating - b.currentRating);
  const top5 = sorted.slice(0,5);
  const card = document.createElement('div');
  card.className = 'club-card';
  card.dataset.name = loc.name.toLowerCase();
  card.innerHTML =
    '<div class="card-header"><h3><a href="#" class="loc-link">' + esc(loc.name) + '</a></h3></div>' +
    '<div class="card-body">' +
    (top5.length === 0
      ? '<div style="padding:14px;text-align:center;color:var(--text-muted);font-size:.83rem">No players found</div>'
      : top5.map((p,i) =>
          '<div class="player-row">' +
            '<span class="rank' + (i===0?' top':'') + '">' + (i+1) + '</span>' +
            '<span class="player-info">' +
              '<span class="player-name">' + esc(p.firstName) + ' ' + esc(p.lastName) + '</span>' +
              (p.teamNames.length ? '<span class="player-team">' + p.teamNames.map(esc).join(' &nbsp;&middot;&nbsp; ') + '</span>' : '') +
            '</span>' +
            '<span class="rating-badge ' + (i===0?'best':'normal') + '">' + fmtR(p.currentRating) + '</span>' +
          '</div>'
        ).join('')) +
    '</div>' +
    '<div class="card-footer">' +
      '<span>' + loc.players.length + ' player' + (loc.players.length!==1?'s':'') + '</span>' +
      (sorted.length > 0 ? '<span style="color:var(--accent);font-weight:600">Best: ' + fmtR(sorted[0].currentRating) + '</span>' : '') +
    '</div>';
  card.querySelector('.loc-link').addEventListener('click', e => { e.preventDefault(); openModal(loc); });
  return card;
}

function openModal(loc) {
  const players = loc.players;
  const bestRating = Math.min(...players.map(p => p.currentRating));
  let sortCol = 7, sortDir = 1; // default: current rating ascending

  const COLS = [
    { label: '#',        key: null },
    { label: 'First',    key: p => (p.firstName||'').toLowerCase() },
    { label: 'Last',     key: p => (p.lastName||'').toLowerCase() },
    { label: 'Team',     key: p => (p.teamNames[0]||'').toLowerCase() },
    { label: 'Division', key: p => (p.division||'').toLowerCase() },
    { label: 'Start',    key: p => p.startRating||0 },
    { label: 'Diff',     key: p => p.currentRating - p.startRating },
    { label: 'Current',  key: p => p.currentRating||0 },
  ];

  function renderTable() {
    const sorted = [...players].sort((a,b) => {
      const fn = COLS[sortCol].key;
      const va = fn(a), vb = fn(b);
      return va < vb ? -sortDir : va > vb ? sortDir : 0;
    });

    const thead = '<thead><tr>' + COLS.map((c,i) => {
      if (i === 0) return '<th>#</th>';
      const cls = 'sortable' + (sortCol===i ? (sortDir===1?' sort-asc':' sort-desc') : '');
      return '<th class="' + cls + '" data-col="' + i + '">' + c.label + '</th>';
    }).join('') + '</tr></thead>';

    const tbody = '<tbody>' + (sorted.length ? sorted.map((p,i) => {
      const d = p.currentRating - p.startRating;
      return '<tr>' +
        '<td>' + (i+1) + '</td>' +
        '<td>' + esc(p.firstName) + '</td>' +
        '<td>' + esc(p.lastName) + '</td>' +
        '<td>' + (p.teamNames.length ? p.teamNames.map(esc).join('<br>') : '') + '</td>' +
        '<td>' + (p.division ? '<span class="div-badge">' + esc(p.division) + '</span>' : '') + '</td>' +
        '<td>' + fmtR(p.startRating) + '</td>' +
        '<td class="' + diffCls(d) + '">' + fmtR(d) + '</td>' +
        '<td><span class="rating-badge ' + (p.currentRating===bestRating?'best':'normal') + '">' + fmtR(p.currentRating) + '</span></td>' +
        '</tr>';
    }).join('') : '<tr><td colspan="8" style="text-align:center;padding:18px;color:var(--text-muted)">No data</td></tr>') + '</tbody>';

    document.getElementById('modalBody').innerHTML = '<table class="modal-table">' + thead + tbody + '</table>';

    document.querySelectorAll('#modalBody thead th.sortable').forEach(th => {
      th.addEventListener('click', () => {
        const col = parseInt(th.dataset.col);
        sortDir = (sortCol === col) ? -sortDir : 1;
        sortCol = col;
        renderTable();
      });
    });
  }

  document.getElementById('modalTitle').textContent = loc.name;
  document.getElementById('modalFooter').textContent =
    players.length + ' player' + (players.length!==1?'s':'') + ' — click any column header to sort';
  renderTable();
  modal.classList.add('open');
  document.body.style.overflow = 'hidden';
}

function closeModal() { modal.classList.remove('open'); document.body.style.overflow = ''; }
document.getElementById('modalClose').addEventListener('click', closeModal);
modal.addEventListener('click', e => { if (e.target === modal) closeModal(); });
document.addEventListener('keydown', e => { if (e.key === 'Escape') closeModal(); });

document.getElementById('searchInput').addEventListener('input', e => {
  const q = e.target.value.toLowerCase().trim();
  document.querySelectorAll('.club-card').forEach(c => {
    c.dataset.hidden = (q && !c.dataset.name.includes(q)) ? 'true' : 'false';
  });
});

// ── HELPFUL LINKS ─────────────────────────────────────────────
document.getElementById('hlPane').innerHTML =
  '<div class="static-pane">' +
  '<h2>Helpful Links</h2>' +
  '<p><a href="https://www.youtube.com/@paddleevolutionbeyourownco7737" target="_blank" rel="noopener">Paddl Evolution - Learn to be your own coach!</a></p>' +
  '<br><br>' +
  '<p><a href="https://www.youtube.com/@mnvike1/featured" target="_blank" rel="noopener">Jerry Albrikes Tennis</a></p>' +
  '<br><br>' +
  '<p><a href="https://www.youtube.com/@PADDLEPRO" target="_blank" rel="noopener">Paddlepro</a></p>' +
  '<br><br>' +
  '<p><a href="https://www.youtube.com/@MattLemery-Paddle" target="_blank" rel="noopener">KLM\'s own Matt Lemery</a></p>' +
  '<br><br>' +
  '<p><a href="https://www.youtube.com/watch?v=Zxe4g75PQ30&t=1477s" target="_blank" rel="noopener">Three Mortgage Bros talk Paddle</a></p>' +
  '</div>';

// ── RELEASE NOTES ─────────────────────────────────────────────
document.getElementById('rnPane').innerHTML =
  '<div class="static-pane">' +
  '<h2>Release Notes</h2>' +
  '<p class="version">Version 1.6</p>' +
  '<p>Created by Bill O\'Neill using Claude as an AI development learning tool.</p>' +
  '<p>All data sourced from APTA Chicago. Calculations performed by application are untested.</p>' +
  '<p><strong>1.4</strong> &mdash; Added Top Series Stats page.</p>' +
  '<p><strong>1.4</strong> &mdash; Added content protection on comments.</p>' +
  '<p><strong>1.5</strong> &mdash; Corrected DIFF field on ratings page and added sorting.</p>' +
  '<p><strong>1.6</strong> &mdash; Added links tab.</p>' +
  '</div>';

// ── FEEDBACK / COMMENTS ───────────────────────────────────────
const GH_TOKEN  = 'github_pat_11B722JGY0ZElnrJxs0kCZ_' + 'IxdW4OoPEShVzKGObx10prthw1EYR4Ukqfvle2C1H1eEHTW3ZTY77wWj4OW';

const BAD_WORDS = ['ass','asshole','bastard','bitch','bollocks','bullshit','cock','crap','cunt','damn','dick','dildo','douche','dumbass','faggot','fag','fuck','fucker','fucking','goddamn','hell','jackass','jerk','motherfucker','nigger','nigga','piss','prick','pussy','retard','shit','slut','twat','wanker','whore'];
function containsProfanity(text) {
  const normalized = text.toLowerCase().replace(/[^a-z0-9\s]/g, '');
  return BAD_WORDS.some(w => new RegExp('\\b' + w + '\\b').test(normalized));
}
const GH_API    = 'https://api.github.com/repos/billoneill1127-source/SWPaddle/contents/comments.json';
const GH_RAW    = 'https://raw.githubusercontent.com/billoneill1127-source/SWPaddle/main/comments.json';

document.getElementById('fbPane').innerHTML =
  '<div class="static-pane">' +
  '<h2>Feedback</h2>' +
  '<p style="font-style:italic;font-size:.88rem;color:var(--text-muted)">I am interested in what you think and what else you might find helpful on this site. Please give your feedback here. I make no promises to read or react to it. Thank you!</p>' +
  '<form class="fb-form" id="fbForm">' +
    '<div><label for="fbName">Your Name (optional)</label><input type="text" id="fbName" placeholder="e.g. John Smith" autocomplete="off"></div>' +
    '<div><label for="fbMsg">Comment</label><textarea id="fbMsg" placeholder="What do you think? What would be helpful?" required></textarea></div>' +
    '<div><button type="submit" class="fb-submit" id="fbSubmit">Post Comment</button><span class="fb-notice" id="fbNotice"></span></div>' +
  '</form>' +
  '<h2 style="margin-top:8px">Comments</h2>' +
  '<div class="comments-list" id="commentsList"><div class="comments-empty">Loading comments...</div></div>' +
  '</div>';

function renderComments(comments) {
  const list = document.getElementById('commentsList');
  if (!list) return;
  if (!comments.length) { list.innerHTML = '<div class="comments-empty">No comments yet. Be the first!</div>'; return; }
  list.innerHTML = comments.slice().reverse().map(c =>
    '<div class="comment-card">' +
    '<div class="comment-meta"><span class="comment-name">' + esc(c.name || 'Anonymous') + '</span>' + esc(c.date) + '</div>' +
    '<div class="comment-text">' + esc(c.text) + '</div>' +
    '</div>'
  ).join('');
}

async function loadComments() {
  try {
    const res = await fetch(GH_RAW + '?t=' + Date.now());
    const data = res.ok ? await res.json() : [];
    renderComments(data);
    return data;
  } catch(e) { renderComments([]); return []; }
}

document.getElementById('fbForm').addEventListener('submit', async function(e) {
  e.preventDefault();
  const name = document.getElementById('fbName').value.trim();
  const text = document.getElementById('fbMsg').value.trim();
  if (!text) return;
  const notice = document.getElementById('fbNotice');
  if (containsProfanity(text) || containsProfanity(name)) {
    notice.textContent = 'Please keep comments respectful — inappropriate language is not allowed.';
    notice.style.color = '#c53030';
    setTimeout(() => { notice.textContent = ''; }, 5000);
    return;
  }
  const btn = document.getElementById('fbSubmit');
  btn.disabled = true; btn.textContent = 'Posting...';
  try {
    // Get current file SHA + contents
    const metaRes = await fetch(GH_API, { headers: { 'Authorization': 'token ' + GH_TOKEN, 'Accept': 'application/vnd.github.v3+json' } });
    const meta = await metaRes.json();
    const existing = JSON.parse(atob(meta.content.replace(/\n/g,'')));
    const now = new Date();
    const dateStr = now.toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric' }) + ' ' + now.toLocaleTimeString('en-US', { hour:'numeric', minute:'2-digit' });
    existing.push({ name: name || 'Anonymous', text, date: dateStr });
    const newContent = btoa(unescape(encodeURIComponent(JSON.stringify(existing, null, 2))));
    const putRes = await fetch(GH_API, {
      method: 'PUT',
      headers: { 'Authorization': 'token ' + GH_TOKEN, 'Accept': 'application/vnd.github.v3+json', 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: 'Add comment', content: newContent, sha: meta.sha })
    });
    if (!putRes.ok) throw new Error('put failed');
    document.getElementById('fbMsg').value = '';
    document.getElementById('fbName').value = '';
    notice.textContent = 'Comment posted!';
    notice.style.color = '#00845a';
    renderComments(existing);
  } catch(err) {
    notice.textContent = 'Something went wrong. Please try again.';
    notice.style.color = '#c53030';
  }
  btn.disabled = false; btn.textContent = 'Post Comment';
  setTimeout(() => { if (notice) notice.textContent = ''; }, 4000);
});

// Load comments when Feedback tab is opened (lazy)
document.querySelectorAll('.tab-btn').forEach(btn => {
  if (btn.dataset.tab === 'fb') btn.addEventListener('click', loadComments, { once: true });
});

// Boot
prData.forEach(loc => grid.appendChild(renderCard(loc)));
updateHeaderInfo('sw');

} catch(e) {
  document.getElementById('swPane').innerHTML = '<div style="padding:24px;font-family:monospace;color:#c53030;background:#fff3f3;border-radius:8px;margin:24px"><strong>JavaScript Error:</strong><br><br>' + e.message + '<br><br><pre>' + (e.stack||'') + '</pre></div>';
  document.getElementById('clubGrid').innerHTML = '<div style="padding:24px;font-family:monospace;color:#c53030">See SW tab for error details.</div>';
}
</script>
</body>
</html>
HTMLEOF
