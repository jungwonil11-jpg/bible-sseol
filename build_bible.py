#!/usr/bin/env python3
# books.js(BIBLE 데이터) + 폰트를 읽어 단일 HTML "성경 전체 썰 읽으실분" 리더로 빌드
# 구조: 랜딩(정경선택) -> 서재(book grid) -> 책 표지 -> 목차(TOC) -> 본문(chapter)
import base64, os
from canon_meta import CANON_META_JS

BASE = os.path.dirname(os.path.abspath(__file__))

with open(f'{BASE}/gamja_full.woff2', 'rb') as f:
    GAMJA_B64 = base64.b64encode(f.read()).decode()
with open(f'{BASE}/books.js', 'r', encoding='utf-8') as f:
    BOOKS_JS = f.read()

HTML = r'''<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0">
<title>성경 전체 썰 읽으실분</title>
<style>
  @font-face {
    font-family: 'Gamja Flower';
    font-style: normal; font-weight: 400; font-display: swap;
    src: url(data:font/woff2;base64,__GAMJA_B64__) format('woff2');
  }

  :root {
    --paper: #fdf2ec;
    --paper-edge: #fbe7dc;
    --ink: #5a4a42;
    --ink-soft: #a98e80;
    --accent: #e08a6a;
    --accent-soft: #f0b89a;
    --line: #f2ddd0;
    --quote-bg: #fbe5d8;
    --shadow: rgba(214,140,110,0.18);
    --bar-track: #f6e2d6;
  }
  html.dark {
    --paper: #2a211d;
    --paper-edge: #332823;
    --ink: #ecdcd2;
    --ink-soft: #b69e90;
    --accent: #f0a585;
    --accent-soft: #d99070;
    --line: #45352e;
    --quote-bg: #352a24;
    --shadow: rgba(0,0,0,0.45);
    --bar-track: #3a2d27;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }
  html { scroll-behavior: smooth; }
  body {
    background: var(--paper);
    color: var(--ink);
    font-family: 'Apple SD Gothic Neo', 'Malgun Gothic', 'Noto Sans KR', 'Pretendard', system-ui, sans-serif;
    line-height: 1.9;
    transition: background .4s ease, color .4s ease;
    -webkit-font-smoothing: antialiased;
  }
  .hand { font-family: 'Gamja Flower', cursive; }

  /* ===== 진행률 바 ===== */
  #progress-wrap { position: fixed; top: 0; left: 0; right: 0; height: 4px; background: var(--bar-track); z-index: 100; }
  #progress { height: 100%; width: 0%; background: linear-gradient(90deg, var(--accent), var(--accent-soft)); transition: width .1s linear; }

  /* ===== 상단 바 ===== */
  #topbar {
    position: fixed; top: 4px; left: 0; right: 0; z-index: 90;
    display: flex; align-items: center; justify-content: space-between;
    padding: 10px 18px;
    background: color-mix(in srgb, var(--paper) 88%, transparent);
    backdrop-filter: blur(8px); border-bottom: 1px solid var(--line);
  }
  #topbar .brand { font-family: 'Gamja Flower', cursive; font-size: 1.35rem; color: var(--accent); cursor: pointer; user-select: none; }
  #topbar .controls { display: flex; align-items: center; gap: 8px; }
  .canon-badge {
    font-family: 'Gamja Flower', cursive; font-size: .9rem;
    color: var(--accent); background: var(--quote-bg);
    border-radius: 999px; padding: 3px 12px; white-space: nowrap;
  }
  .btn {
    font-family: 'Gamja Flower', cursive; font-size: 1.1rem;
    background: transparent; color: var(--ink-soft);
    border: 1.5px solid var(--line); border-radius: 999px;
    padding: 4px 14px; cursor: pointer; transition: all .25s ease;
  }
  .btn:hover { color: var(--accent); border-color: var(--accent); }

  .page { max-width: 680px; margin: 0 auto; padding: 120px 28px 90px; }
  .view { display: none; }
  .view.active { display: block; animation: fade .5s ease; }
  @keyframes fade { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: none; } }

  /* ===== 랜딩 (정경 선택) ===== */
  #landing { min-height: 100vh; padding: 60px 24px 80px; }
  #landing.active { display: flex !important; flex-direction: column; align-items: center; justify-content: center; }
  .landing-title { font-family: 'Gamja Flower', cursive; font-size: clamp(2.4rem, 9vw, 3.4rem); color: var(--accent); line-height: 1.2; text-align: center; margin-bottom: 10px; }
  .landing-sub { font-family: 'Gamja Flower', cursive; font-size: 1.2rem; color: var(--ink-soft); text-align: center; margin-bottom: 48px; }
  .canon-cards { display: flex; flex-wrap: wrap; gap: 20px; justify-content: center; width: 100%; max-width: 980px; }
  .canon-card {
    flex: 1 1 270px; max-width: 310px;
    border: 2px solid var(--line); border-radius: 22px;
    padding: 30px 24px 24px; cursor: pointer;
    background: var(--paper-edge);
    transition: all .28s ease;
    display: flex; flex-direction: column; gap: 12px;
  }
  .canon-card:hover { border-color: var(--accent); transform: translateY(-8px); box-shadow: 0 20px 40px var(--shadow); }
  .canon-card-name { font-family: 'Gamja Flower', cursive; font-size: 2.2rem; color: var(--accent); line-height: 1; }
  .canon-card-denom { font-size: .8rem; color: var(--ink-soft); }
  .canon-card-count { font-family: 'Gamja Flower', cursive; font-size: 1.5rem; color: var(--ink); }
  .canon-card-count span { font-size: .82rem; color: var(--ink-soft); font-family: system-ui, sans-serif; }
  .canon-card-desc { font-size: .86rem; color: var(--ink-soft); line-height: 1.7; }
  .canon-card-extra {
    font-size: .8rem; line-height: 1.85;
    background: var(--quote-bg); border-radius: 10px;
    padding: 10px 14px; color: var(--ink);
  }
  .canon-card-extra-label { font-size: .72rem; color: var(--ink-soft); display: block; margin-bottom: 3px; }
  .canon-card-btn {
    font-family: 'Gamja Flower', cursive; font-size: 1.15rem;
    background: var(--accent); color: #fff; border: none;
    border-radius: 999px; padding: 11px 24px; cursor: pointer;
    transition: all .2s ease; margin-top: 4px; pointer-events: none;
  }
  .canon-card:hover .canon-card-btn { transform: scale(1.03); }

  /* ===== 서재 ===== */
  #shelf .shelf-head { text-align: center; margin-bottom: 8px; }
  #shelf h1 { font-family: 'Gamja Flower', cursive; font-size: clamp(2.4rem, 9vw, 3.4rem); color: var(--accent); line-height: 1.2; }
  #shelf .shelf-sub { font-family: 'Gamja Flower', cursive; font-size: 1.2rem; color: var(--ink-soft); text-align: center; margin-bottom: 40px; }
  .testament-label {
    font-family: 'Gamja Flower', cursive; font-size: 1.5rem; color: var(--accent);
    margin: 8px 0 18px; padding-bottom: 6px; border-bottom: 2px dashed var(--line);
  }
  .book-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 16px; margin-bottom: 40px; }
  .book-card {
    border: 1px solid var(--line); border-radius: 16px; overflow: hidden;
    background: var(--paper-edge); cursor: pointer; transition: all .25s ease;
    display: flex; flex-direction: column;
  }
  .book-card:hover { transform: translateY(-4px); box-shadow: 0 10px 24px var(--shadow); border-color: var(--accent); }
  .book-card .cover { width: 100%; aspect-ratio: 3/4; object-fit: cover; background: var(--quote-bg); display: block; }
  .book-card .cover.placeholder { display: flex; align-items: center; justify-content: center; font-family: 'Gamja Flower', cursive; font-size: 2.4rem; color: var(--accent-soft); }
  .book-card .label { padding: 12px 10px; text-align: center; }
  .book-card .label .t { font-family: 'Gamja Flower', cursive; font-size: 1.4rem; color: var(--accent); }
  .book-card .label .r { font-size: .78rem; color: var(--ink-soft); margin-top: 2px; }
  .book-card.coming { opacity: .45; cursor: default; pointer-events: none; }
  .coming-badge { display: inline-block; font-size: .7rem; background: var(--accent-soft); color: #fff; border-radius: 999px; padding: 2px 8px; margin-top: 5px; }
  .empty-note { font-family: 'Gamja Flower', cursive; font-size: 1.1rem; color: var(--ink-soft); opacity: .7; text-align: center; padding: 20px; }

  /* ===== 책 표지 ===== */
  #cover { position: relative; min-height: 100vh; flex-direction: column; align-items: center; justify-content: flex-start; text-align: center; }
  #cover.active { display: flex; }
  #cover .cover-img { position: absolute; bottom: 0; left: 50%; transform: translateX(-50%); width: 100%; max-width: 560px; object-fit: contain; z-index: 0; pointer-events: none; }
  #cover .cover-text { position: relative; z-index: 2; margin-top: 11vh; padding: 0 24px; }
  #cover h1 { font-family: 'Gamja Flower', cursive; font-size: clamp(2.6rem, 11vw, 4.2rem); color: var(--accent); line-height: 1.2; margin-bottom: 14px; }
  #cover .sub { font-family: 'Gamja Flower', cursive; font-size: clamp(1.05rem, 4.2vw, 1.35rem); color: var(--ink-soft); }
  #cover .start { position: relative; z-index: 3; margin-top: 4vh; font-family: 'Gamja Flower', cursive; font-size: 1.5rem; background: var(--accent); color: #fff; border: none; border-radius: 999px; padding: 10px 40px; cursor: pointer; box-shadow: 0 8px 20px var(--shadow); transition: transform .2s ease; }
  #cover .start:hover { transform: translateY(-3px) scale(1.02); }

  /* ===== 목차 ===== */
  #toc h2 { font-family: 'Gamja Flower', cursive; font-size: 2.4rem; text-align: center; color: var(--accent); margin-bottom: 6px; }
  #toc .toc-sub { font-family: 'Gamja Flower', cursive; text-align: center; color: var(--ink-soft); font-size: 1.1rem; margin-bottom: 34px; }
  .toc-item { display: flex; align-items: baseline; gap: 14px; padding: 15px 16px; margin-bottom: 10px; border: 1px solid var(--line); border-radius: 12px; background: var(--paper-edge); cursor: pointer; transition: all .25s ease; text-align: left; }
  .toc-item:hover { border-color: var(--accent); transform: translateX(4px); box-shadow: 0 4px 12px var(--shadow); }
  .toc-item .no { font-family: 'Gamja Flower', cursive; font-size: 1.7rem; color: var(--accent-soft); min-width: 38px; }
  .toc-item .info .t { font-weight: 700; font-size: 1.08rem; color: var(--accent); }
  .toc-item .info .r { font-size: .82rem; color: var(--ink-soft); margin-top: 2px; }

  /* ===== 챕터 본문 ===== */
  .chapter { display: none; }
  .chapter.active { display: block; animation: fade .5s ease; }
  /* 제2경전 추가분 — 개신교(show-deut 없음)에서는 숨김 */
  body:not(.show-deut) .canon-extra { display: none; }
  .canon-extra { border-left: 3px solid var(--accent-soft); background: var(--quote-bg); border-radius: 0 12px 12px 0; padding: 16px 20px; margin: 24px 0; }
  .canon-extra > p:first-child, .canon-extra > p:last-child { margin-bottom: 0; }
  .canon-extra .ce-label { font-family: 'Gamja Flower', cursive; font-size: 1.05rem; color: var(--accent); display: block; margin-bottom: 8px; }
  .chapter .ch-head { text-align: center; margin-bottom: 34px; }
  .chapter .ch-num { font-family: 'Gamja Flower', cursive; font-size: 1.1rem; color: var(--accent-soft); letter-spacing: .2em; }
  .chapter h2.ch-title { font-family: 'Gamja Flower', cursive; font-size: 2.2rem; color: var(--accent); margin: 6px 0 4px; }
  .chapter .ch-ref { font-size: .85rem; color: var(--ink-soft); }
  .chapter .divider { width: 60px; height: 2px; background: var(--accent-soft); margin: 18px auto 0; opacity: .6; }
  .chapter p { margin: 0 0 18px; font-size: 1.07rem; }
  .chapter ul { margin: 0 0 18px; padding-left: 22px; }
  .chapter li { margin-bottom: 8px; font-size: 1.05rem; }
  .chapter strong { color: var(--accent); font-weight: 700; }
  .chapter .quote { background: var(--quote-bg); border-left: 4px solid var(--accent-soft); padding: 14px 18px; margin: 0 0 20px; border-radius: 4px; color: var(--ink); }
  .ch-nav { display: flex; justify-content: space-between; gap: 12px; margin-top: 52px; padding-top: 24px; border-top: 1px dashed var(--line); }
  .ch-nav button { flex: 1; font-family: 'Gamja Flower', cursive; font-size: 1.15rem; padding: 12px; border-radius: 10px; cursor: pointer; border: 1px solid var(--line); background: var(--paper-edge); color: var(--ink); transition: all .25s ease; }
  .ch-nav button:hover:not(:disabled) { border-color: var(--accent); color: var(--accent); }
  .ch-nav button:disabled { opacity: .3; cursor: default; }
  .ch-nav .toc-btn { flex: 0 0 auto; min-width: 90px; color: var(--ink-soft); }

  @media (max-width: 600px) {
    .canon-cards { flex-direction: column; align-items: center; }
    .canon-card { max-width: 100%; flex: none; width: 100%; }
    .landing-sub { margin-bottom: 28px; }
  }
  @media (max-width: 520px) {
    .page { padding: 110px 18px 70px; }
    .chapter p, .chapter li { font-size: 1.02rem; }
    .ch-nav { flex-wrap: wrap; }
    .ch-nav .toc-btn { order: -1; flex: 1 1 100%; }
    #topbar .brand { font-size: 1rem; }
    .canon-badge { display: none; }
    .btn { padding: 4px 10px; font-size: .95rem; }
  }
</style>
</head>
<body>

<div id="progress-wrap"><div id="progress"></div></div>

<div id="topbar" style="display:none;">
  <div class="brand" onclick="goShelf()">📖 성경 전체 썰 읽으실분</div>
  <div class="controls">
    <span id="canon-badge" class="canon-badge"></span>
    <button class="btn" onclick="goLanding()">정경변경</button>
    <button class="btn" id="back-btn" onclick="goBack()">뒤로</button>
    <button class="btn" id="theme-btn" onclick="toggleTheme()">🌙 다크</button>
  </div>
</div>

<!-- 랜딩 (정경 선택) — 진입 시 첫 화면 -->
<section id="landing" class="view active">
  <div class="landing-title hand">성경 전체<br>썰 읽으실분</div>
  <div class="landing-sub hand">어떤 성경으로 읽을까요?</div>
  <div class="canon-cards" id="landing-cards"></div>
</section>

<!-- 서재 -->
<section id="shelf" class="view page">
  <div class="shelf-head"><h1 class="hand">성경 전체<br>썰 읽으실분</h1></div>
  <div class="shelf-sub hand" id="shelf-sub-text">친구가 풀어주는 성경</div>
  <div id="shelf-old"></div>
  <div id="shelf-deut-wrap" style="display:none;"><div id="shelf-deut"></div></div>
  <div id="shelf-new"></div>
</section>

<!-- 책 표지 -->
<section id="cover" class="view"></section>

<!-- 목차 -->
<section id="toc" class="view page">
  <h2 id="toc-title">목 차</h2>
  <div class="toc-sub hand">읽고 싶은 편 누르면 바로 감</div>
  <div id="toc-list"></div>
</section>

<!-- 본문 -->
<section id="reader" class="view page"><div id="chapters"></div></section>

<script>
__BOOKS_JS__
</script>

<script>
  var state = { book: null, chapter: 0, canon: null, chapters: [] };

__CANON_META_JS__

  // ===== 랜딩 =====
  function renderLanding() {
    var keys = ['protestant', 'catholic', 'orthodox'];
    for (var i = keys.length - 1; i > 0; i--) {
      var j = Math.floor(Math.random() * (i + 1));
      var tmp = keys[i]; keys[i] = keys[j]; keys[j] = tmp;
    }
    var html = '';
    keys.forEach(function(k) {
      var info = CANON_INFO[k];
      var extraHtml = '';
      if (info.extra.length > 0) {
        extraHtml = '<div class="canon-card-extra">' +
          '<span class="canon-card-extra-label">개신교 대비 추가 성경</span>' +
          info.extra.join(' · ') +
          '</div>';
      }
      html += '<div class="canon-card" onclick="selectCanon(\'' + k + '\')">' +
        '<div class="canon-card-name hand">' + info.name + '</div>' +
        '<div class="canon-card-denom">' + info.denominations + '</div>' +
        '<div class="canon-card-count hand">📖 ' + info.total + '권 <span>(구약 ' + info.oldCount + ' + 신약 ' + info.newCount + ')</span></div>' +
        '<div class="canon-card-desc">' + info.desc + '</div>' +
        extraHtml +
        '<button class="canon-card-btn hand">이 성경으로 읽기 →</button>' +
        '</div>';
    });
    document.getElementById('landing-cards').innerHTML = html;
  }

  function selectCanon(c) {
    state.canon = c;
    document.body.classList.toggle('show-deut', c === 'catholic' || c === 'orthodox');
    var info = CANON_INFO[c];
    document.getElementById('canon-badge').textContent = info.name + ' ' + info.total + '권';
    document.getElementById('shelf-sub-text').textContent = '친구가 풀어주는 성경 ' + info.total + '권 · ' + info.name;
    renderShelf();
    showView('shelf');
  }

  function goLanding() {
    state.book = null; state.chapter = 0;
    renderLanding();
    showView('landing');
  }

  // ===== 서재 =====
  function renderShelf() {
    // B안: 구약 + (선택 정경의) 제2경전을 order(sortKey)로 병합 정렬해 "구약" 한 섹션에 렌더.
    var oldBooks = BIBLE.old.slice();
    if (state.canon === 'catholic' || state.canon === 'orthodox') {
      var realDeut = BIBLE.deut || [];
      DEUT_META.forEach(function(meta) {
        if (meta.canon.indexOf(state.canon) === -1) return;
        var real = realDeut.find(function(b) { return b.id === meta.id; });
        if (real) {
          oldBooks.push(Object.assign({}, real, { order: meta.order }));
        } else {
          oldBooks.push({ id: meta.id, title: meta.title, ref: meta.ref, order: meta.order,
            canon: meta.canon, status: 'coming_soon', cover: '', chapters: [] });
        }
      });
      oldBooks.sort(function(a, b) { return a.order - b.order; });
    }
    document.getElementById('shelf-deut-wrap').style.display = 'none';
    renderTestament('shelf-old', '구약', oldBooks);
    renderTestament('shelf-new', '신약', BIBLE.new);
  }

  function renderTestament(elId, label, books) {
    var wrap = document.getElementById(elId);
    if (!wrap) return;
    var html = '<div class="testament-label hand">' + label + '</div>';
    if (!books || books.length === 0) {
      html += '<div class="empty-note">곧 추가됩니다 ✦</div>';
      wrap.innerHTML = html;
      return;
    }
    html += '<div class="book-grid">';
    books.forEach(function(bk) {
      var coming = bk.status === 'coming_soon';
      var coverHtml = bk.cover
        ? '<img class="cover" src="' + bk.cover + '" alt="' + bk.title + '">'
        : '<div class="cover placeholder hand">' + bk.title.charAt(0) + '</div>';
      var clickAttr = coming ? '' : ' onclick="openBook(\'' + bk.id + '\')"';
      var comingBadge = coming ? '<div class="coming-badge">준비 중</div>' : '';
      html += '<div class="book-card' + (coming ? ' coming' : '') + '"' + clickAttr + '>' +
        coverHtml +
        '<div class="label"><div class="t hand">' + bk.title + '</div>' +
        '<div class="r">' + (bk.ref || '') + '</div>' +
        comingBadge + '</div></div>';
    });
    html += '</div>';
    wrap.innerHTML = html;
  }

  // ===== 책 찾기 =====
  function findBook(id) {
    var all = BIBLE.old.concat(BIBLE.new).concat(BIBLE.deut || []);
    return all.find(function(b) { return b.id === id; });
  }

  // ===== 표지 =====
  function renderCover(bk) {
    var el = document.getElementById('cover');
    var img = bk.cover ? '<img class="cover-img" src="' + bk.cover + '" alt="' + bk.title + '">' : '';
    el.innerHTML = img +
      '<div class="cover-text"><h1 class="hand">친구가 읽어주는<br>' + bk.title + '</h1>' +
      '<div class="sub hand">' + (bk.ref || '') + '</div></div>' +
      '<button class="start hand" onclick="goToc()">읽으러 가기 &rarr;</button>';
  }

  // ===== 목차 =====
  function renderToc(bk) {
    document.getElementById('toc-title').textContent = bk.title;
    var list = document.getElementById('toc-list');
    var html = '';
    state.chapters.forEach(function(ch, i) {
      var n = i + 1;
      html += '<div class="toc-item" onclick="openChapter(' + n + ')">' +
        '<div class="no hand">' + String(n).padStart(2, '0') + '</div>' +
        '<div class="info"><div class="t">' + ch.title + '</div>' +
        '<div class="r">' + ch.ref + '</div></div></div>';
    });
    list.innerHTML = html;
  }

  // ===== 본문 =====
  function renderChapters(bk) {
    var wrap = document.getElementById('chapters');
    var total = state.chapters.length;
    var html = '';
    state.chapters.forEach(function(ch, i) {
      var n = i + 1;
      var prevD = n === 1 ? 'disabled' : '';
      var nextD = n === total ? 'disabled' : '';
      html += '<section class="chapter" id="ch-' + n + '">' +
        '<div class="ch-head"><div class="ch-num hand">EPISODE ' + String(n).padStart(2, '0') + '</div>' +
        '<h2 class="ch-title hand">' + ch.title + '</h2><div class="ch-ref">' + ch.ref + '</div>' +
        '<div class="divider"></div></div>' +
        '<div class="ch-body">' + ch.html + '</div>' +
        '<div class="ch-nav">' +
        '<button ' + prevD + ' onclick="openChapter(' + (n - 1) + ')">← 이전편</button>' +
        '<button class="toc-btn" onclick="goToc()">목차</button>' +
        '<button ' + nextD + ' onclick="openChapter(' + (n + 1) + ')">다음편 →</button>' +
        '</div></section>';
    });
    wrap.innerHTML = html;
  }

  // ===== 뷰 전환 =====
  function showView(id) {
    ['landing', 'shelf', 'cover', 'toc', 'reader'].forEach(function(v) {
      document.getElementById(v).classList.toggle('active', v === id);
    });
    var topbar = document.getElementById('topbar');
    topbar.style.display = (id === 'landing') ? 'none' : 'flex';
    document.getElementById('back-btn').style.display = (id === 'shelf') ? 'none' : '';
    window.scrollTo(0, 0);
    updateProgress();
  }

  function goShelf() { state.book = null; state.chapter = 0; showView('shelf'); }

  // 현재 정경에서 보이는 챕터만 (canon 없는 본편은 항상 보임)
  function visibleChapters(bk) {
    return bk.chapters.filter(function(ch) {
      return !ch.canon || ch.canon.indexOf(state.canon) !== -1;
    });
  }

  function openBook(id) {
    var bk = findBook(id);
    if (!bk || !bk.chapters || bk.chapters.length === 0) return;
    state.book = bk; state.chapter = 0;
    state.chapters = visibleChapters(bk);
    renderCover(bk); renderToc(bk); renderChapters(bk);
    showView('cover');
  }

  function goToc() { state.chapter = 0; showView('toc'); }

  function openChapter(n) {
    var bk = state.book;
    if (!bk) return;
    if (n < 1 || n > state.chapters.length) return;
    state.chapter = n;
    document.querySelectorAll('#chapters .chapter').forEach(function(el) { el.classList.remove('active'); });
    document.getElementById('ch-' + n).classList.add('active');
    showView('reader');
  }

  function goBack() {
    if (state.chapter >= 1) { goToc(); return; }
    if (document.getElementById('toc').classList.contains('active')) { showView('cover'); return; }
    goShelf();
  }

  // ===== 진행률 =====
  function updateProgress() {
    var bar = document.getElementById('progress');
    if (!state.book || state.chapter === 0) { bar.style.width = '0%'; return; }
    var total = state.chapters.length;
    var docH = document.documentElement.scrollHeight - window.innerHeight;
    var scrolled = docH > 0 ? (window.scrollY / docH) : 0;
    var base = (state.chapter - 1) / total;
    bar.style.width = Math.min(100, (base + scrolled / total) * 100).toFixed(1) + '%';
  }
  window.addEventListener('scroll', updateProgress, { passive: true });

  // ===== 다크모드 =====
  function toggleTheme() {
    document.documentElement.classList.toggle('dark');
    var dark = document.documentElement.classList.contains('dark');
    document.getElementById('theme-btn').textContent = dark ? '☀️ 라이트' : '🌙 다크';
  }

  // ===== 키보드 =====
  document.addEventListener('keydown', function(e) {
    if (state.chapter >= 1) {
      if (e.key === 'ArrowRight') openChapter(state.chapter + 1);
      if (e.key === 'ArrowLeft') openChapter(state.chapter - 1);
    }
  });

  // 초기화 — 랜딩부터 시작
  renderLanding();
</script>
</body>
</html>'''

HTML = HTML.replace('__BOOKS_JS__', BOOKS_JS)
HTML = HTML.replace('__CANON_META_JS__', CANON_META_JS)
HTML = HTML.replace('__GAMJA_B64__', GAMJA_B64)

with open(f'{BASE}/bible_reader.html', 'w', encoding='utf-8') as f:
    f.write(HTML)

print("빌드 완료: bible_reader.html")
print("파일 크기:", os.path.getsize(f'{BASE}/bible_reader.html')//1024, "KB")
