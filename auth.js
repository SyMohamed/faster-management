/**
 * auth.js — Shared authentication guard for FASTER Lab workspace.
 * Include this script in <head> of every sub-page (BEFORE any other scripts).
 * Redirects to index.html if the user has not signed in.
 *
 * Exposes globals for sub-pages:
 *   window.FASTER_USER      — display name  (e.g. "Waleed Ahmad")
 *   window.FASTER_UNAME     — username      (e.g. "waleed")
 *   window.FASTER_ROLE      — "admin" | "member" | "viewer"
 *   window.FASTER_IS_ADMIN  — boolean
 *   window.FASTER_READONLY  — boolean (true for guest/viewer mode)
 */
(function () {
  var AUTH_KEY  = 'faster_auth_v1';
  var USER_KEY  = 'faster_user_v1';
  var UNAME_KEY = 'faster_uname_v1';
  var ROLE_KEY  = 'faster_role_v1';

  if (sessionStorage.getItem(AUTH_KEY) !== 'ok') {
    try { sessionStorage.setItem('faster_redirect', location.href); } catch(e){}
    location.replace('index.html');
    return;
  }

  window.FASTER_USER     = sessionStorage.getItem(USER_KEY)  || '';
  window.FASTER_UNAME    = sessionStorage.getItem(UNAME_KEY) || '';
  window.FASTER_ROLE     = sessionStorage.getItem(ROLE_KEY)  || 'member';
  window.FASTER_IS_ADMIN = window.FASTER_ROLE === 'admin';
  window.FASTER_READONLY = window.FASTER_ROLE === 'viewer';

  /* Auto-set admin flag for sub-pages (assets.html etc.) */
  if (window.FASTER_IS_ADMIN) {
    sessionStorage.setItem('fa', '1');
  }

  /* ── Read-only mode restrictions ───────────────────────────────────── */
  if (window.FASTER_READONLY) {

    document.addEventListener('DOMContentLoaded', function () {
      /* Readonly banner at bottom of page */
      var banner = document.createElement('div');
      banner.id = 'faster-readonly-banner';
      banner.style.cssText = [
        'position:fixed', 'bottom:0', 'left:0', 'right:0',
        'background:#f59e0b', 'color:#000',
        'text-align:center', 'padding:9px 16px',
        'font-size:15px', 'font-weight:600',
        'z-index:9990', 'font-family:monospace',
        'box-shadow:0 -2px 12px rgba(0,0,0,.3)'
      ].join(';');
      banner.innerHTML = '\uD83D\uDC41 View-only mode &mdash; ' +
        '<a href="index.html" style="color:inherit;text-decoration:underline">sign in as a member</a>' +
        ' to make changes';
      document.body.appendChild(banner);

      /* Add extra bottom padding so banner doesn't overlap content */
      document.body.style.paddingBottom = '48px';
    });

    /* Block all form submissions */
    document.addEventListener('submit', function (e) {
      e.preventDefault();
      e.stopImmediatePropagation();
      _readonlyToast();
    }, true);

    /* Block write button clicks (heuristic: text or onclick contains write keywords) */
    var WRITE_WORDS = ['add','creat','save','delet','remov','updat','edit',
                       'submit','approv','reject','log','export','import','new '];
    document.addEventListener('click', function (e) {
      var el = e.target.closest('button, [role="button"]');
      if (!el) return;
      var text = (el.textContent + ' ' + (el.getAttribute('onclick') || '')).toLowerCase();
      if (WRITE_WORDS.some(function(w){ return text.includes(w); })) {
        e.preventDefault();
        e.stopImmediatePropagation();
        _readonlyToast();
      }
    }, true);
  }

  function _readonlyToast() {
    var existing = document.getElementById('_ro_toast');
    if (existing) return;
    var t = document.createElement('div');
    t.id = '_ro_toast';
    t.style.cssText = [
      'position:fixed', 'top:22px', 'left:50%',
      'transform:translateX(-50%)',
      'background:#f59e0b', 'color:#000',
      'padding:10px 22px', 'border-radius:9px',
      'z-index:99999', 'font-size:15px',
      'font-family:monospace', 'font-weight:600',
      'pointer-events:none', 'transition:opacity .4s'
    ].join(';');
    t.textContent = '\uD83D\uDC41 View-only \u2014 sign in as a member to make changes';
    document.body.appendChild(t);
    setTimeout(function () {
      t.style.opacity = '0';
      setTimeout(function () { t.remove(); }, 400);
    }, 2500);
  }
})();
